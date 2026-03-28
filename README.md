# PriceTrail

PriceTrail é uma aplicação móvel que ajuda os utilizadores a otimizar as suas compras de supermercado, identificando os melhores preços em diferentes lojas e gerando a rota mais eficiente para realizar as compras.

A aplicação foi desenvolvida com forte foco na experiência do utilizador em contexto real, sendo pensada para utilização em movimento (rua, transportes, ambiente dinâmico).

---

## Funcionalidades

### Autenticação

* Registo e login de utilizadores (Email/Password e OAuth)
* Gestão segura de sessões

### Listas de Compras

* Criação e gestão de múltiplas listas
* Interface baseada em cartões para fácil utilização
* Adição e remoção rápida de produtos

### Pesquisa Inteligente

* Pesquisa dinâmica (search-as-you-type)
* Sugestões com imagem, nome e preço médio
* Filtros rápidos (Promoções, Marca Branca, Mais Próximo)

### Otimização de Rota

* Geração de rotas otimizadas entre várias lojas
* Definição de preferências (número máximo de lojas, tipo de transporte)
* Fluxo passo-a-passo (Stepper)

### Mapa Interativo

* Integração com Google Maps API
* Visualização da rota em tempo real
* Sequência de lojas com tempos de deslocação

### Comparação de Preços

* Visualização de preços por produto em diferentes supermercados
* Destaque automático da opção mais económica
* Uso de Bottom Sheets para detalhe sem mudança de ecrã

### Notificações

* Alertas de alteração de preços
* Lembretes de compras
* Notificações contextuais relevantes

### Perfil e Estatísticas

* Acompanhamento da poupança
* Histórico de compras
* Definições do utilizador

---

## Princípios de UX/UI

A aplicação segue boas práticas modernas de design móvel:

* Utilização com uma mão
* Interações rápidas (máximo de 3 ações por tarefa principal)
* Hierarquia visual clara
* Redução de carga cognitiva
* Feedback imediato ao utilizador
* Navegação simples e consistente
* Acessibilidade (contraste, tipografia e legibilidade)

### Padrões de Interface Utilizados

* Bottom Navigation
* Layout baseado em cartões
* Stepper para fluxos complexos
* Bottom Sheets para detalhe
* Floating Action Button (FAB)

---

## Tecnologias Utilizadas

* Framework: Flutter
* Backend: Firebase
* Autenticação: Firebase Authentication
* Base de Dados: Cloud Firestore
* Notificações: Firebase Cloud Messaging
* Mapas e Rotas: Google Maps API

---

## Estrutura do Projeto

```bash
lib/
│── core/           # constantes, temas, utilitários
│── features/
│   ├── auth/
│   ├── lists/
│   ├── explore/
│   ├── route/
│   ├── profile/
│── widgets/        # componentes reutilizáveis
│── main.dart
```

---

## Instalação e Execução

1. Clonar o repositório

```bash
git clone https://github.com/your-username/pricetrail.git
cd pricetrail
```

2. Instalar dependências

```bash
flutter pub get
```

3. Executar a aplicação

```bash
flutter run
```

---

## Requisitos

* Flutter SDK instalado
* Projeto Firebase configurado
* Chaves de API para Google Maps API

---

## Melhorias Futuras

* Previsão de preços com base em dados históricos
* Modo offline
* Listas partilhadas entre utilizadores
* Integração com comandos de voz
* Recomendações personalizadas

---

## Aviso

A aplicação depende de fontes externas para dados de preços e mapas. A precisão da informação está dependente da fiabilidade dessas fontes.

---

## Equipa de Desenvolvimento

* [202200359@estudantes.ips.pt](mailto:202200359@estudantes.ips.pt) - Felisberto de Carvalho
* [2024146419@estudantes.ips.pt](mailto:2024146419@estudantes.ips.pt) - Alex
* [2024149191@estudantes.ips.pt](mailto:2024149191@estudantes.ips.pt) - Joana Lagarto
* [2024149382@estudantes.ips.pt](mailto:2024149382@estudantes.ips.pt) - Diogo Pina

---

## Licença

Projeto desenvolvido para fins académicos.
