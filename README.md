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

- **Iniciando a Criação da VPC:** A VPC será a estrutura principal do projeto, responsável por isolar e gerenciar a rede. Acesse o console da AWS, navegue até o serviço "VPC" e clique em "Create VPC".

  ![Imagem VPC](/images/vpc1.png)
  ![Imagem VPC](/images/vpc2.png)

- **Ação de Criação:** Na tela de criação, insira as informações necessárias, como o nome da VPC e o bloco CIDR IPv4 (ex.: 10.0.0.0/16). Revise os detalhes e clique em "Create VPC" para finalizar.

  ![Imagem VPC](/images/vpc3.png)

- **Criação e Associação de um Internet Gateway (IGW):** Para permitir a saída de tráfego da VPC para a internet, crie um Internet Gateway. Vá até a seção "Internet Gateways", clique em "Create Internet Gateway" e forneça um nome.

  ![Imagem IGW](/images/vpc4.png)
  ![Imagem IGW](/images/vpc5.png)

- **Associação do IGW à VPC:** Após criar o IGW, selecione-o na lista, clique em "Actions" e escolha "Attach to VPC". No campo "Select a VPC", escolha a VPC criada anteriormente e clique em "Attach Internet Gateway".

  ![Imagem IGW](/images/vpc6.png)
  ![Imagem IGW](/images/vpc7.png)

- **Verificação:** Com o IGW associado, a VPC estará configurada com acesso à internet, permitindo a comunicação externa necessária para o projeto.

### Passo 2: Configuração e Criação das Subnets

- **Objetivo:** Nesta etapa, criaremos quatro subnets (duas para o RDS e duas para as instâncias EC2) para garantir uma distribuição adequada e alta disponibilidade.

- **Criação das Subnets para EC2:**

  - Acesse o console da AWS, navegue até o serviço "VPC", vá para a aba "Subnets" e clique em "Create Subnet".

    ![Imagem Subnet](/images/subnet1.png)

  - Selecione a VPC criada no Passo 1 pelo nome. Escolha zonas de disponibilidade diferentes (ex.: us-east-1a e us-east-1b) para maximizar a redundância. Defina os blocos CIDR IPv4 (ex.: 10.0.0.0/18 e 10.0.64.0/18) e clique em "Create Subnet" para finalizar.

    ![Imagem Subnet](/images/subnet2.png)
    ![Imagem Subnet](/images/subnet3.png)

- **Criação das Subnets para RDS:**

  - Repita o processo de criação de subnets, alterando apenas o nome e os blocos CIDR (ex.: 10.0.128.0/18 e 10.0.192.0/18). Certifique-se de usar zonas de disponibilidade assim como foi feito para a subnet das EC2: us-east-1a e us-east-1b.

    ![Imagem Subnet](/images/subnet4.png)
    ![Imagem Subnet](/images/subnet5.png)

- **Configuração das Route Tables:**

  - Para permitir que as subnets do WordPress se conectem à internet, configure as tabelas de rotas. Acesse a aba "Route Tables" no console VPC e clique em "Create Route Table".

    ![Imagem Subnet](/images/subnet6.png)

  - Insira um nome para a tabela de rotas, selecione a VPC criada anteriormente e clique em "Create Route Table".

    ![Imagem Subnet](/images/subnet7.png)

  - Edite as rotas clicando em "Edit Routes". Adicione uma rota para redirecionar todo o tráfego (0.0.0.0/0) ao Internet Gateway (IGW) criado no Passo 1, selecione o IGW correspondente no campo "Target" e salve as alterações.

    ![Imagem Subnet](/images/subnet8.png)
    ![Imagem Subnet](/images/subnet9.png)

  - Após criar a tabela de rotas, associe-a às subnets das instâncias EC2 para garantir o acesso à internet. No console da AWS, na aba "Route Tables", selecione a tabela criada, clique em "Actions" e escolha "Edit Subnet Associations". Marque as duas subnets destinadas às EC2, verifique as seleções e clique em "Save Associations" para aplicar as alterações.

    ![Imagem Subnet](/images/subnet10.png)
    ![Image Subnet](/images/subnet11.png)

- **Verificação:** Com isso, as quatro subnets estarão criadas (duas públicas para EC2 e duas privadas para RDS), e as tabelas de rotas estarão configuradas para acesso à internet.
