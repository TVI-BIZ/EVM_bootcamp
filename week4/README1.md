
# Lesson 15 - NodeJS API using NestJS framework

## NestJS Framework

* Running services with node
* Web server with node
* Using Express to run a node web server
* About using frameworks
* Using NestJS framework
* Overview of a NestJS project
* Using the CLI
* Initializing a project with NestJS
* Swagger plugin

### References

<https://nodejs.org/en/docs/guides/getting-started-guide/>

<https://devdocs.io/express-getting-started/>

<https://docs.nestjs.com/>

<https://docs.nestjs.com/openapi/introduction>

<https://www.coreycleary.me/what-is-the-difference-between-controllers-and-services-in-node-rest-apis>

<https://restfulapi.net/idempotent-rest-apis/>

<https://docs.nestjs.com/openapi/types-and-parameters>

## Implementing the API

* The NestJS CLI
* Creating Resources
* Controllers, Services and Routes in NestJS
* Modules and injections (overview)
* Server configuration
* Serving script operations as API services
* Params, DTOs and Payloads
* HTTP errors and messages
* (Review) Environment
* Implementing the features

## Read-only data

* GET methods:
  * GET contract address
  * GET token name
  * GET total supply
  * GET balance of a given address
  * GET transaction receipt of a transaction by transaction hash

### Example GET Method for Contract Address

* Controller method for GET `contract-address`:

```typescript
  @Get('contract-address')
  getContractAddress(){
    return {result: this.appService.getContractAddress()};
  }
```

* Implementing `getContractAddress` service at `app.service.ts`:

```typescript
  getContractAddress(): string {
    return "0x2282A77eC5577365333fc71adE0b4154e25Bb2fa";
  }
```

### Example GET Method for Token Name

* Controller method for GET `token-name`:

```typescript
  @Get('token-name')
  async getTokenName() {
    return {result: await this.appService.getTokenName()};
  }
```

* Fetching the ABI for creating a `Contract` with Ethers:
  * Pick your `MyToken.json` from any ERC20 that you compiled before
  * Copy it and paste at `src/assets/`
  * Import the file at `app.service.ts`:

```typescript
import * as tokenJson from './assets/MyToken.json';
```

* Add the `resolveJsonModule` configuration to `compilerOptions` inside `tsconfig.json`:

```json
"resolveJsonModule": true
```

* Implementing `getTokenName` service at `app.service.ts`:

```typescript
  async getTokenName(): Promise<string> {
    const publicClient = createPublicClient({
      chain: sepolia,
      transport: http(`>Put your RPC endpoint URL here<`),
    });
    const name = await publicClient.readContract({
      address: this.getContractAddress(),
      abi: tokenJson.abi,
      functionName: "name"
    });
    return name;
  }
```

### Using environment variables

* Add `dotenv` to your project and configure it at `main.ts`:

```bash
npm i --save dotenv
```

```typescript
...
import 'dotenv/config';
require('dotenv').config();

async function bootstrap() {
...
```

* Create your `.env` file at the root of your project:

```txt
PRIVATE_KEY=****************************************************************
RPC_ENDPOINT_URL="https://****************************************************************"
TOKEN_ADDRESS="0x****************************************"
```

* Modify the `getTokenName` service:

```typescript
  getContractAddress(): string {
    return process.env.TOKEN_ADDRESS;
  }

  async getTokenName(): Promise<string> {
    const publicClient = createPublicClient({
      chain: sepolia,
      transport: http(process.env.RPC_ENDPOINT_URL),
    });
    const name = await publicClient.readContract({
      address: this.getContractAddress(),
      abi: tokenJson.abi,
      functionName: "name"
    });
    return name;
  }
```

### Using NestJS Configurations Module

* Remove `dotenv` configurations at `main.ts`:

```typescript
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
...
```

* Add `@nestjs/config` to your project

```bash
npm i --save @nestjs/config
```

* Import `ConfigModule` in `app.module.ts`

```typescript
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [ConfigModule.forRoot()],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

* Import `ConfigService` inside `app.service.ts`:

```typescript
  constructor(private configService: ConfigService) {}
```

* Refactor `getContractAddress` and `getTokenName`:

```typescript
  getContractAddress(): string {
    return this.configService.get<string>('TOKEN_ADDRESS');
  }

  async getTokenName(): Promise<string> {
    const publicClient = createPublicClient({
      chain: sepolia,
      transport: http(this.configService.get<string>('RPC_ENDPOINT_URL')),
    });
    const name = await publicClient.readContract({
      address: this.getContractAddress(),
      abi: tokenJson.abi,
      functionName: "name"
    });
    return name;
  }
```

### Adding Swagger Module

* Install `@nestjs/swagger` to your project

```bash
npm install --save @nestjs/swagger
```

* Configure your `main.ts` file:

```typescript
import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const config = new DocumentBuilder()
    .setTitle('API example')
    .setDescription('The API description')
    .setVersion('1.0')
    .addTag('example')
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api', app, document);

  await app.listen(3000);
}
bootstrap();
```

### Other Controller GET Methods

* Adding the GET methods at `app.controller.ts`:

```typescript
  @Get('total-supply')
  async getTotalSupply() {
    return {result: await this.appService.getTotalSupply()};
  }

  @Get('token-balance/:address')
  async getTokenBalance(@Param('address') address: string) {
    return {result: await this.appService.getTokenBalance(address)};
  }

  @Get('transaction-receipt')
  async getTransactionReceipt(@Query('hash') hash: string) {
    return {result: await this.appService.getTransactionReceipt(hash)};
  }
```

* Organizing the `AppService` class:

```typescript
export class AppService {
  publicClient;

  constructor(private configService: ConfigService) {
    this.publicClient = createPublicClient({
      chain: sepolia,
      transport: http(this.configService.get<string>('RPC_ENDPOINT_URL')),
    });
  }
  ...
```

## Minting tokens

* GET methods:
  * Get the address of the server wallet
  * Check if address has MINTER_ROLE role
* POST methods:
  * Request tokens to be minted
 
### Implementation

* Controller methods:

```typescript
  @Get('server-wallet-address')
  getServerWalletAddress() {
    return {result: this.appService.getServerWalletAddress()};
  }

  @Get('check-minter-role')
  checkMinterRole(@Query('address') address: string) {
    return {result: await this.appService.checkMinterRole(address)};
  }

  @Post('mint-tokens')
  async mintTokens(@Body() body: any) {
    return {result: await this.appService.mintTokens(body.address)};
  }
```

* Creating the `MintTokenDto` class at `src/dtos/mintToken.dto.ts`:

```typescript
import { ApiProperty } from "@nestjs/swagger";

export class MintTokenDto {
    @ApiProperty({type: String, required: true, default: "My Address"})
    address: string;
}
```

* Using `MintTokenDto` for the `mintTokens` method:

```typescript
...
import { MintTokenDto } from './dtos/mintToken.dto';

@Controller()
export class AppController {
  ...

  @Post('mint-tokens')
  async mintTokens(@Body() body: MintTokenDto) {
    return {result: await this.appService.mintTokens(body.address)};
  }
}
```

## Coupling frontend and APIs

* On-chain and off-chain features
* Keeping user Private Key private
* Mapping interactions, resources and payloads
* Handling errors

### References

<https://en.wikipedia.org/wiki/Loose_coupling>

<https://react.dev/reference/react/useEffect#fetching-data-with-effects>

### Implementing the coupling

* Change port to `3001` at `main.ts` (backend):
  
```typescript
await app.listen(3001);
```

* Edit Home page in the frontend at `packages/nextjs/pages/index.tsx`:

```bash
cd ../..
code ./scaffold-eth-2/packages/nextjs/pages/index.tsx
```

* Create a new Component for `ApiData`:

```tsx
function ApiData(params: { address: `0x${string}` }) {
  return (
    <div className="card w-96 bg-primary text-primary-content mt-4">
      <div className="card-body">
        <h2 className="card-title">Testing API Coupling</h2>
        <p>TODO</p>
      </div>
    </div>
  );
}
```

* Modify `WalletInfo` to add `ApiData` Component:

```tsx
    if (address)
    return (
      <div>
        <p>Your account address is {address}</p>
        <p>Connected to the network {chain?.name}</p>
        <WalletAction></WalletAction>
        <WalletBalance address={address as `0x${string}`}></WalletBalance>
        <TokenInfo address={address as `0x${string}`}></TokenInfo>
        <ApiData address={address as `0x${string}`}></ApiData>
      </div>
    );
```

* Create a new Component for `TokenAddressFromApi`:

```tsx
function TokenAddressFromApi() {
  const [data, setData] = useState<{ result: string }>();
  const [isLoading, setLoading] = useState(true);

  useEffect(() => {
    fetch("http://localhost:3001/contract-address")
      .then((res) => res.json())
      .then((data) => {
        setData(data);
        setLoading(false);
      });
  }, []);

  if (isLoading) return <p>Loading token address from API...</p>;
  if (!data) return <p>No token address information</p>;

  return (
    <div>
      <p>Token address from API: {data.result}</p>
    </div>
  );
}
```

* Put `TokenAddressFromApi` inside `ApiData` Component:

```tsx
        <TokenAddressFromApi></TokenAddressFromApi>
        <p>TODO</p>
```

## CORS settings

* Cross-origin resource sharing
* Allow origin errors

### Code reference

* Modifying `main.ts` (backend):

```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors();
  ...
```

### References

<https://docs.nestjs.com/security/cors>

<https://github.com/expressjs/cors#configuration-options>

---

## Sending a POST call

* Building a Payload
* Using DTOs

### References

<https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST>

<https://jasonwatmore.com/post/2020/02/01/react-fetch-http-post-request-examples>

<https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type>

### Implementation example

* Create the `RequestTokens` Component:

```tsx
function RequestTokens(params: { address: string }) {
  const [data, setData] = useState<{ result: boolean }>();
  const [isLoading, setLoading] = useState(false);

  const body = { address: params.address };

  if (isLoading) return <p>Requesting tokens from API...</p>;
  if (!data)
    return (
      <button
        className="btn btn-active btn-neutral"
        onClick={() => {
          setLoading(true);
          fetch("http://localhost:3001/mint-tokens", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(body),
          })
            .then((res) => res.json())
            .then((data) => {
              setData(data);
              setLoading(false);
            });
        }}
      >
        Request tokens
      </button>
    );

  return (
    <div>
      <p>Result from API: {data.result ? 'worked' : 'failed'}</p>
    </div>
  );
}
```

* Put `RequestTokens` inside `ApiData` Component:

```tsx
        <TokenAddressFromApi></TokenAddressFromApi>
        <RequestTokens address={params.address}></RequestTokens>
```

* Implement `mintTokens` at `app.service.ts` to return something:

```typescript
  async mintTokens(address: string) {
    return { result: true };
  }
```

* TODO: Implement the mint transaction and return the hash for displaying it in the frontend.

## Homework

* Create Github Issues with your questions about this lesson
* Read the references
