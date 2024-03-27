
# Teste back-end speedio

Como comentado com o Rafael, meu primeiro contato claro com ruby. Foquei em fazer um código que atendesse as expectativas de forma limpa e coesa, apesar de nao conhecer ainda as boas praticas da linguagem.

Não optei por usar rails ou qualquer outro framework por julgar que seria overkill para a task.
# API de Web Scraping

Esta é uma API para realizar web scraping de informações de sites utilizando o SimilarWeb.

## Endpoints

- **`POST /salve_info`**: Este endpoint recebe uma URL de um site como entrada. Ele executa o scraping dos dados correspondentes a essa URL no SimilarWeb e salva as informações no MongoDB.

- **`POST /get_info`**: Este endpoint recebe uma URL como entrada. Ele busca as informações do site correspondente a essa URL no banco de dados e as retorna. Se as informações ainda não estiverem disponíveis no banco de dados, o endpoint retorna um código de erro.

## Uso

1. **`POST /salve_info`**:
   - **Método**: `POST`
   - **Corpo da solicitação**: Deve incluir um objeto JSON com a seguinte estrutura:
     ```json
     {
       "url": "google.com"
     }
     ```
   - **Resposta de Sucesso**: Retorna um objeto JSON com um ID de trabalho único para a operação de scraping iniciada.
   - **Exemplo de Requisição**:
     ```bash
     curl -X POST http://localhost:4567/salve_info -H "Content-Type: application/json" -d '{"url": "google.com"}'
     ```

2. **`POST /get_info`**:
   - **Método**: `POST`
   - **Corpo da solicitação**: Deve incluir um objeto JSON com a seguinte estrutura:
     ```json
     {
       "url": "google.com"
     }
     ```
   - **Resposta de Sucesso**: Retorna um objeto JSON com as informações do site correspondente à URL fornecida.
   - **Exemplo de Requisição**:
     ```bash
     curl -X POST http://localhost:4567/get_info -H "Content-Type: application/json" -d '{"url": "google.com"}'
     ```

---

Este é um projeto simples para demonstrar o uso de web scraping com a API do SimilarWeb. Para qualquer dúvida ou sugestão, entre em contato pelo email: robertolamim@gmail.com.
    