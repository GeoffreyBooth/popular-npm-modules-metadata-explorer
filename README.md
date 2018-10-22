# Popular NPM Modules Metadata Explorer

This repo lets you use JavaScript to execute queries against the `package.json` files of [the most popular modules in the NPM registry](https://github.com/anvaka/npmrank). The code creates a cache folder to cache the list of modules and their `package.json` metadata files, for increased speed on subsequent runs. You can specify how far down the list of popular packages you want to search (default is the top 1000) and you can tell it to invalidate the cache (for fresh data).

## Usage: CoffeeScript

If you’re comfortable with CoffeeScript, the CoffeeScript REPL is a little easier to use as it allows `await` outside of an async function. As you can see in the query examples below, the query code is very similar to JavaScript.

From the root of the repo, install dependencies and start the CoffeeScript REPL:

```bash
$ npm install
$ npx coffee
```

In the CoffeeScript REPL, load this module to get the top 5000 NPM registry modules’ `package.json`’s, in an array sorted by popularity:

```coffee
coffee> packages = await require('.')({limit: 5000}); null
```

* The `null` is to avoid the REPL printing all 5000 objects in the `packages` array.
* If `limit` is omitted, the top 1000 packages are returned.
* Call like `require('.')({limit: 5000, useCache: no})` to fetch fresh data.

Now run some queries on the data. How many packages use the `main` field?

```coffee
coffee> packages.filter((p) => p.main?).length
```

Which package names start with `@`?

```coffee
coffee> packages.filter((p) => p.name.startsWith('@')).map((p) => p.name)
```

What are the top 50 packages that depend on CoffeeScript?

```coffee
coffee> packages.filter((p) => p.dependencies?['coffeescript'] or p.devDependencies?['coffeescript'] or p.peerDependencies?['coffeescript'] or p.dependencies?['coffee-script'] or p.devDependencies?['coffee-script'] or p.peerDependencies?['coffee-script']).map((p) => p.name)[0...50]
```

## Usage: JavaScript

If you’re okay with the defaults, you can start the Node REPL with a `packages` variable defined as an array of the `package.json` files of the top 1000 NPM modules:

```bash
$ npm install
$ npm start
```

To customize the arguments, first start the Node.js REPL:

```bash
$ node
```

Then in the Node.js REPL, load this module to get the top 5000 NPM registry modules’ `package.json`’s, in an array sorted by popularity:

```js
> require('coffeescript/register')
> let packages
> (async function() { packages = await require('.')({limit: 5000}); })()
```

* Before continuing, make sure you wait until `packages` is defined.
* If `limit` is omitted, the top 1000 packages are returned.
* Call like `require('.')({limit: 5000, useCache: no})` to fetch fresh data.

Now run some queries on the data. How many packages use the `main` field?

```js
> packages.filter((p) => p.main).length
```

Which package names start with `@`?

```js
> packages.filter((p) => p.name.startsWith('@')).map((p) => p.name)
```

What are the top 50 packages that depend on Lodash?

```js
> packages.filter((p) => (p.dependencies && p.dependencies['lodash']) || (p.devDependencies && p.devDependencies['lodash']) || (p.peerDependencies && p.peerDependencies['lodash'])).map((p) => p.name).slice(0, 50)
```
