# Projeto - [ AWS / Wordpress ] - Compass UOL

## Visão Geral

Este projeto descreve uma arquitetura de implantação escalável do WordPress na Amazon Web Services (AWS). A configuração garante alta disponibilidade, balanceamento de carga e escalabilidade automática para lidar eficientemente com variações no tráfego.

## Arquitetura

- **Virtual Private Cloud (VPC):** Toda a infraestrutura é hospedada dentro de uma VPC para um ambiente de rede seguro e isolado.
- **Zonas de Disponibilidade:** Duas zonas de disponibilidade (Zona de Disponibilidade 1 e Zona de Disponibilidade 2) são utilizadas para redundância e tolerância a falhas.
- **Balanceador de Carga:** Um Balanceador de Carga da AWS distribui o tráfego de entrada entre várias instâncias EC2 para evitar um único ponto de falha e otimizar a utilização de recursos.
- **Instâncias EC2:** Múltiplas instâncias EC2 executam o WordPress, com cada instância hospedada em uma zona de disponibilidade diferente.
- **Grupo de Auto Scaling:** Ajusta automaticamente o número de instâncias EC2 com base nas políticas de escalabilidade definidas para gerenciar picos de tráfego.
- **Amazon RDS:** Um serviço de banco de dados relacional gerenciado (RDS) armazena o banco de dados do WordPress, garantindo persistência e escalabilidade dos dados.

## Uso

- Os usuários acessam o site WordPress através da URL do balanceador de carga.
- O sistema escala automaticamente o número de instâncias EC2 com base na carga de tráfego, garantindo desempenho e disponibilidade.

## Pré-requisitos

- Conta na AWS com permissões apropriadas.
- Conhecimento básico dos serviços da AWS (EC2, RDS, Balanceador de Carga, Auto Scaling).

## Passo a Passo de Implementação

### Passo 1: Configuração e Criação da VPC

- **Iniciando a Criação da VPC:** A VPC será a base fundamental do projeto, responsável por isolar e gerenciar a rede de forma segura. Acesse o console da AWS, navegue até o serviço "VPC" e clique em "Create VPC" para iniciar o processo.

  ![Imagem VPC](/images/vpc1.png)
  ![Imagem VPC](/images/vpc2.png)

- **Configuração Inicial:** Na tela de criação, selecione a opção "VPC and more" para uma configuração completa. Defina um nome desejado para a VPC, utilize o bloco CIDR IPv4 como 10.0.0.0/16 por padrão, e configure "Number of Availability Zones" como 2, escolhendo us-east-1a e us-east-1b para garantir redundância.

  ![Imagem VPC](/images/vpc3.png)

- **Definição de Subnets e Recursos:** Escolha 2 subnets públicas (para o ALB) e 2 subnets privadas (para EC2 e RDS), adicione 1 NAT Gateway por zona de disponibilidade para acesso à internet das subnets privadas, e deixe "VPC Endpoints" como "None". Ative as opções "Enable DNS Hostnames" e "DNS Resolution" para suporte a resolução de nomes. Finalize clicando em "Create VPC" para concluir a criação.

  ![Imagem IGW](/images/vpc4.png)

- **Verificação da Estrutura:** Após a criação, a VPC estará configurada com 2 subnets privadas (para EC2 e RDS), 2 subnets públicas (para o ALB), 2 NAT Gateways e 1 Internet Gateway (IGW), formando uma infraestrutura robusta e escalável.

  ![Imagem IGW](/images/vpc5.png)

### Passo 2: Configuração e Criação das Security Groups

- **Criação Inicial das Security Groups:** Neste passo, criaremos os security groups necessários para o projeto. Acesse o console da AWS, navegue até "Security Groups", e clique em "Create Security Group" para criar quatro grupos sem regras iniciais. Nomeie-os de forma descritiva (ex.: `wordpress-sgp`, `efs-sgp`, `rds-sgp`, `alb-sgp`) para refletir suas funções (WordPress, EFS, RDS e ALB, respectivamente). Selecione a VPC criada no Passo 1 e finalize a criação de cada um.

  - ![Imagem Security Group](/images/sgp1.png)

- **Configuração do Security Group `wordpress-sgp`:** Selecione o `wordpress-sgp`, clique em "Actions" e escolha "Edit Inbound Rules". Adicione uma regra do tipo "HTTP" com origem `alb-sgp` e outra do tipo "NFS" com origem `efs-sgp`. Salve as alterações. Em seguida, vá para "Outbound Rules", clique em "Add Rule" e deixe as regras padrão (permitindo todo o tráfego, a ser ajustado conforme necessário).

  - ![Imagem Security Group](/images/sgp2.png)
  - ![Imagem Security Group](/images/sgp5.png)
  - ![Imagem Security Group](/images/sgp3.png)
  - ![Imagem Security Group](/images/sgp4.png)

- **Configuração do Security Group `rds-sgp`:** Selecione o `rds-sgp`, edite as "Inbound Rules" e adicione uma regra do tipo "MySQL/Aurora" com origem `wordpress-sgp`. Nas "Outbound Rules", adicione a mesma regra ("MySQL/Aurora" com origem `wordpress-sgp`) para garantir a comunicação bidirecional.

  - ![Image Security Group](/images/sgp6.png)
  - ![Image Security Group](/images/sgp7.png)

- **Configuração do Security Group `alb-sgp`:** Selecione o `alb-sgp`, edite as "Inbound Rules" e adicione uma regra do tipo "HTTP" permitindo tráfego de qualquer origem (0.0.0.0/0) para acesso público. Nas "Outbound Rules", adicione uma regra do tipo "HTTP" com origem `wordpress-sgp`.

  - ![Image Security Group](/images/sgp8.png)
  - ![Image Security Group](/images/sgp9.png)

- **Configuração do Security Group `efs-sgp`:** Selecione o `efs-sgp`, edite as "Inbound Rules" e adicione uma regra do tipo "NFS" com origem `wordpress-sgp`. Nas "Outbound Rules", adicione uma regra do tipo "NFS" com origem `wordpress-sgp` para limitar o tráfego ao necessário.

  - ![Image Security Group](/images/sgp10.png)
  - ![Image Security Group](/images/sgp11.png)

- **Verificação:** Com essas configurações, os quatro security groups estarão prontos para suportar a infraestrutura. Abaixo está uma tabela resumindo as configurações de inbound e outbound:

| Security Group  | Direção  | Protocolo    | Porta | Origem/Destino   |
| --------------- | -------- | ------------ | ----- | ---------------- |
| `wordpress-sgp` | Inbound  | HTTP         | 80    | `alb-sgp`        |
| `wordpress-sgp` | Inbound  | NFS          | 2049  | `efs-sgp`        |
| `wordpress-sgp` | Outbound | (Padrão)     | -     | (Todo o tráfego) |
| `rds-sgp`       | Inbound  | MySQL/Aurora | 3306  | `wordpress-sgp`  |
| `rds-sgp`       | Outbound | MySQL/Aurora | 3306  | `wordpress-sgp`  |
| `alb-sgp`       | Inbound  | HTTP         | 80    | 0.0.0.0/0        |
| `alb-sgp`       | Outbound | HTTP         | 80    | `wordpress-sgp`  |
| `efs-sgp`       | Inbound  | NFS          | 2049  | `wordpress-sgp`  |
| `efs-sgp`       | Outbound | NFS          | 2049  | `wordpress-sgp`  |

### Passo 3: Configuração e Criação do RDS

- **Criação do DB Subnet Group:** Para associar o RDS às subnets, acesse a aba "Subnet Groups" no serviço RDS e clique em "Create DB Subnet Group". Insira um nome e descrição, selecione a VPC criada, escolha duas zonas de disponibilidade (AZs) correspondentes às subnets previamente configuradas, selecione as subnets privadas e clique em "Create".

  ![Image DB Security Group](/images/rds3.png)
  ![Image DB Security Group](/images/rds4.png)

- **Criação do Banco de Dados MySQL no RDS:** Navegue até a aba "Databases" no RDS e clique em "Create Database" para iniciar a configuração do banco de dados.

  ![Image RDS](/images/rds5.png)

- **Seleção da Engine:** Escolha a engine "MySQL" como base para o banco de dados.

  ![Image DB](/images/rds6.png)

- **Configuração do Template e Disponibilidade:** Opte pelo template "Free Tier" e selecione "Single AZ DB Instance Deployment" para esta configuração inicial.

  ![Image DB](/images/rds7.png)

- **Definição de Credenciais:** Insira um nome de identificação para a instância do DB, defina o "Master Username" e o "Master Password" como "wordpress" (recomenda-se usar senhas fortes em produção).

  ![Image DB](/images/rds8.png)

- **Associação de Rede:** Selecione a VPC criada, o DB Subnet Group configurado e o Security Group criado anteriormente.

  ![Image DB](/images/rds9.png)

- **Autenticação do Banco de Dados:** Configure a autenticação como "Password Authentication".

  ![Image DB](/images/rds10.png)

- **Criação do Banco Inicial:** Defina o nome do banco de dados inicial como "wordpress".

  ![Image DB](/images/rds11.png)

- **Verificação:** Com essas etapas concluídas, o banco de dados MySQL estará criado e configurado no RDS, pronto para uso com o WordPress.

### Passo 4: Configuração e Criação do EFS

- **Criação do Sistema de Arquivos EFS:** Com o security group pronto, navegue até o serviço "EFS" no console da AWS e clique em "Create File System".

  ![Image EFS](/images/efs3.png)

- **Personalização da Configuração:** Selecione a opção "Customize" para ajustar as configurações manualmente.

  ![Image EFS](/images/efs4.png)

- **Definição do Nome:** Insira um nome para o sistema de arquivos e clique em "Next" para prosseguir.

  ![Image EFS](/images/efs5.png)

- **Configuração de Acesso à Rede:** Na seção "Network Access", selecione a VPC criada, adicione as subnets destinadas às EC2 configuradas anteriormente e associe o security group criado para o EFS. Revise as configurações e clique em "Next" até finalizar com "Create".

  ![Image EFS](/images/efs6.png)

- **Verificação:** Após a criação, o sistema de arquivos EFS estará configurado e pronto para ser utilizado pelo ambiente WordPress.
