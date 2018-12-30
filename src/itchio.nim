## **Docs, Info, etc:** https://itch.io/docs/api/serverside
import asyncdispatch, httpclient, strutils, json, xmltree, xmlparser

const
  itchioApiUrl* = "https://itch.io/api/1/"                   ## itch.io API URL (SSL).
  lastGamesUploadedUrl = "https://itch.io/feed/new.xml"      ## Last Games Uploaded to itch.io URL (SSL).
  lastGamesFeaturedUrl = "https://itch.io/feed/featured.xml" ## Last Games Featured on itch.io URL (SSL).
  lastActiveSalesUrl = "https://itch.io/feed/sales.xml"      ## Last Games on Sales on itch.io URL (SSL).
  lastGamesFreeUrl = "https://itch.io/games/price-free.xml"  ## Last Games for Free on itch.io URL (SSL).

type
  ItchioBase*[HttpType] = object ## Base object.
    timeout*: byte  ## Timeout Seconds for API Calls, byte type, 1~255.
    proxy*: Proxy  ## Network IPv4 / IPv6 Proxy support, Proxy type.
    api_key*: string ## Required valid Itchio API Key string.
  Itchio* = ItchioBase[HttpClient]           ##  Sync Itchio API Client.
  AsyncItchio* = ItchioBase[AsyncHttpClient] ## Async Itchio API Client.

using gameId: string

template clientify(this: Itchio | AsyncItchio): untyped =
  ## Build & inject basic HTTP Client with Proxy and Timeout.
  var client {.inject.} =
    when this is AsyncItchio: newAsyncHttpClient(
      proxy = when declared(this.proxy): this.proxy else: nil, userAgent="")
    else: newHttpClient(
      timeout = when declared(this.timeout): this.timeout.int * 1_000 else: -1,
      proxy = when declared(this.proxy): this.proxy else: nil, userAgent="")
  client.headers = newHttpHeaders({
    "dnt": "1", "accept": "application/json", "content-type": "application/json"})

proc lastGamesUploaded*(this: Itchio | AsyncItchio): Future[XmlNode] =
  ## Return the latest games uploaded to Itchio.
  clientify(this)
  result =
    when this is AsyncItchio: parseXml(await client.getContent(lastGamesUploadedUrl))
    else: parseXml(client.getContent(lastGamesUploadedUrl))

proc lastGamesFeatured*(this: Itchio | AsyncItchio): Future[XmlNode] =
  ## Return the latest games featured on Itchio.
  clientify(this)
  result =
    when this is AsyncItchio: parseXml(await client.getContent(lastGamesFeaturedUrl))
    else: parseXml(client.getContent(lastGamesFeaturedUrl))

proc lastActiveSales*(this: Itchio | AsyncItchio): Future[XmlNode] =
  ## Return the latest games on active sale promo on Itchio.
  clientify(this)
  result =
    when this is AsyncItchio: parseXml(await client.getContent(lastActiveSalesUrl))
    else: parseXml(client.getContent(lastActiveSalesUrl))

proc lastGamesFree*(this: Itchio | AsyncItchio): Future[XmlNode] =
  ## Return the latest free games on Itchio.
  clientify(this)
  result =
    when this is AsyncItchio: parseXml(await client.getContent(lastGamesFreeUrl))
    else: parseXml(client.getContent(lastGamesFreeUrl))

proc credentials*(this: Itchio | AsyncItchio): Future[JsonNode] =
  ## Returns information of credentials used to make this API request.
  ## Includes list of scopes the credentials give access to. Takes no parameters.
  clientify(this)
  let url = itchioApiUrl & this.api_key & "/credentials/info"
  result =
    when this is AsyncItchio: parseJson(await client.getContent(url))
    else: parseJson(client.getContent(url))

proc me*(this: Itchio | AsyncItchio): Future[JsonNode] =
  ## Return public profile data for user owner of the API key. Takes no parameters.
  clientify(this)
  let url = itchioApiUrl & this.api_key & "/me"
  result =
    when this is AsyncItchio: parseJson(await client.getContent(url))
    else: parseJson(client.getContent(url))

proc myGames*(this: Itchio | AsyncItchio): Future[JsonNode] =
  ## Return public profile data about all the games user uploaded or have edit access. Takes no parameters.
  clientify(this)
  let url = itchioApiUrl & this.api_key & "/my-games"
  result =
    when this is AsyncItchio: parseJson(await client.getContent(url))
    else: parseJson(client.getContent(url))

proc game*(this: Itchio | AsyncItchio, gameId, download_key="", user_id="", email=""): Future[JsonNode] =
  ## Return Checks if a download key exists for game and returns it.
  doAssert download_key != "" or user_id != "" or email != "", "Must have at least 1 of download_key or user_id or email"
  clientify(this)
  var url: string
  if download_key != "":
    url = itchioApiUrl & this.api_key & "/game/" & gameId & "/" & download_key
  elif user_id != "":
    url = itchioApiUrl & this.api_key & "/game/" & gameId & "/" & user_id
  elif email != "":
    url = itchioApiUrl & this.api_key & "/game/" & gameId & "/" & email
  result =
    when this is AsyncItchio: parseJson(await client.getContent(url))
    else: parseJson(client.getContent(url))

proc purchases*(this: Itchio | AsyncItchio, gameId, user_id="", email=""): Future[JsonNode] =
  ## Return Checks if a download key exists for game and returns it.
  doAssert user_id != "" or email != "", "Must have at least 1 of download_key or user_id or email"
  clientify(this)
  var url: string
  if user_id != "":
    url = itchioApiUrl & this.api_key & "/game/" & gameId & "/purchases/" & user_id
  elif email != "":
    url = itchioApiUrl & this.api_key & "/game/" & gameId & "/purchases/" & email
  result =
    when this is AsyncItchio: parseJson(await client.getContent(url))
    else: parseJson(client.getContent(url))
