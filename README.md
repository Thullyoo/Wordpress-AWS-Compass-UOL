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
