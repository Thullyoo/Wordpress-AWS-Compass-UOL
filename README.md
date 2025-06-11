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

![Imagem arquitetura](/images/arquitetura.png)

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

### Passo 5: Configuração e Criação do Target Groups

- **Iniciando a Criação do Target Group:** Acesse o console da AWS, navegue até o serviço "Target Groups" (geralmente encontrado na seção do Load Balancer), e clique em "Create Target Group" para começar o processo.

  - ![Image Tg](/images/tg1.png)

- **Configuração do Target Group:** Escolha o tipo "Instances" como alvo, insira um nome descritivo para o target group, selecione a VPC criada no Passo 1 para garantir compatibilidade de rede, e clique em "Next". Revise as configurações e finalize clicando em "Create Target Group".

  - ![Image Tg](/images/tg2.png)

  - ![Image Tg](/images/tg3.png)

- **Verificação:** Com isso, o target group estará criado e pronto para ser associado às instâncias EC2 criadas pelo Auto Scaling posteriormente, direcionando o tráfego de forma eficiente.

### Passo 6: Configuração e Criação do Application Load Balancer

- **Iniciando a Criação do Load Balancer:** Acesse o console da AWS, navegue até o serviço "Load Balancers", clique em "Create Load Balancer" e selecione a opção "Application Load Balancer" para iniciar o processo.

  - ![Image ALB](/images/alb1.png)
  - ![Image ALB](/images/alb2.png)

- **Configuração Básica:** Insira um nome descritivo para o Application Load Balancer (ALB) e escolha a opção "Internet-facing" para permitir acesso público.

  - ![Image ALB](/images/alb3.png)

- **Definição de Rede:** Selecione a VPC criada anteriormente e adicione as subnets públicas correspondentes às zonas de disponibilidade us-east-1a e us-east-1b para garantir alta disponibilidade.

  - ![Image ALB](/images/alb4.png)

- **Configuração Final:** Associe o security group `alb-sgp` criado no Passo 2 e configure o listener para direcionar o tráfego ao target group criado no Passo 4. Revise as configurações e clique em "Create" para finalizar a criação do ALB.

  - ![Image ALB](/images/alb5.png)

- **Verificação:** Com isso, o Application Load Balancer estará configurado e pronto para distribuir o tráfego entre as instâncias EC2.

### Passo 7: Configuração e Criação do Launch Template

- **Iniciando a Criação do Launch Template:** Acesse o console da AWS, navegue até o serviço "EC2", vá para a aba "Launch Templates" e clique em "Create Launch Template" para começar o processo.

  ![Image LT](/images/lt1.png)

- **Configuração Básica:** Insira um nome descritivo para o launch template e selecione o sistema operacional "Amazon Linux 2023 AMI" como base para as instâncias EC2.

  ![Image LT](/images/lt2.png)

- **Associação do Security Group:** Escolha o security group `wordpress-sgp` criado no Passo 2 para garantir que as instâncias tenham as permissões de rede adequadas.

  ![Image LT](/images/lt3.png)

- **Configuração do User Data:** No campo "User Data", insira o script `user_data.sh`, substituindo `EFS_ID=` pelo ID do EFS criado no Passo 4 e `DB_URL=` pelo endpoint do RDS configurado no Passo 3. Isso permitirá que as instâncias se conectem ao EFS e ao banco de dados automaticamente. Logo após isso so clicar em Create Launch template para terminar a criação.

  ![Image LT](/images/lt4.png)

- **Verificação:** Com essas etapas concluídas, o launch template estará pronto para ser usado pelo grupo de auto scaling, garantindo a inicialização consistente das instâncias.

### Passo 8: Configuração e Criação do Auto Scaling

- **Iniciando a Criação do Auto Scaling Group:** Acesse o console da AWS, navegue até o serviço "EC2", localize a seção "Auto Scaling Groups" e clique em "Create Auto Scaling group" para iniciar o processo.

  - ![Image ats](/images/ats.png)

- **Configuração do Nome e Launch Template:** Insira um nome único para o grupo, e selecione o launch template criado no Passo 7. Escolha a versão padrão (1) para garantir a consistência das configurações das instâncias.

  - ![Image ats](/images/ats2.png)

- **Definição de Opções de Lançamento:** Na seção "Instance launch options", opte por "Specify instance attributes" para personalizar os requisitos de computação. Defina um mínimo de 1 vCPU e um máximo de 2 vCPUs, bem como um mínimo de 1 GiB e um máximo de 2 GiB de memória por instância, permitindo flexibilidade na seleção de tipos de instâncias.

  - ![Image ats](/images/ats3.png)

- **Integração com Load Balancer:** Na seção "Integrate with other services", escolha "Attach to an existing load balancer" e selecione o target group `tg-wordpress | HTTP` associado ao Application Load Balancer `alb-wordpress` criado no Passo 6, garantindo a distribuição de tráfego.

  - ![Image ats](/images/ats4.png)

- **Configuração da Rede:** Selecione a VPC criada no Passo 1 e configure as subnets privadas `wp-subnet-private-us-east-1a` e `wp-subnet-private-us-east-1b` para hospedar as instâncias. Escolha a opção "Balanced distribution across Availability Zones" para alta disponibilidade.

  - ![Image ats](/images/ats5.png)

- **Definição de Tamanho e Escalabilidade:** Na seção "Configure group size and scaling", defina a capacidade desejada como 2 instâncias, com um mínimo de 2 e um máximo de 4 instâncias. Opte por "No scaling policies" inicialmente, permitindo ajustes manuais ou automáticos futuros conforme a demanda.

  - ![Image ats](/images/ats6.png)

- **Verificação e Criação:** Revise todas as configurações e clique em "Create Auto Scaling group" para finalizar. O grupo estará pronto para lançar instâncias automaticamente com base nas políticas definidas.

### Passo 9: Testes

- **Acesso ao Load Balancer:** Acesse o console da AWS, navegue até o serviço "Load Balancers", localize o Application Load Balancer criado no Passo 6 e copie o DNS name associado a ele para testar a conectividade.

  - ![](/images/ats8.png)

- **Teste no Navegador:** Cole o DNS name copiado na barra de endereço de um navegador e pressione Enter. Isso deve exibir a tela de instalação inicial do WordPress, indicando que a infraestrutura está funcionando corretamente.

  - ![](/images/ats7.png)

- **Verificação:** Confirme que a página de instalação do WordPress aparece sem erros, sinalizando que o ALB, as instâncias EC2, o EFS e o RDS estão devidamente integrados e acessíveis.

- Imagem com o site customizado:

  - ![](/images/ats9.png)
