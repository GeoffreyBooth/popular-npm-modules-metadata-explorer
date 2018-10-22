fs = require 'mz/fs'
path = require 'path'
del = require 'del'
request = require 'request-promise-native'
packageJson = require 'package-json'
filenamify = require 'filenamify'
queue = require 'async/queue'


cacheFolder = path.join process.cwd(), '.cache'
metadataCacheFolder = path.join cacheFolder, 'packages-metadata'


# Create the cache folders if they doesn’t already exist
createCacheFolders = ->
	for folder in [cacheFolder, metadataCacheFolder]
		try
			await fs.mkdir folder
		catch exception
			throw exception unless exception.code is 'EEXIST'


# Return an array of the names of every package in the NPM registry, sorted by rank
getListOfNpmPackages = ->
	dataSource = 'http://anvaka.github.io/npmrank/online/npmrank.json'
	try
		data = await fs.readFile path.join(cacheFolder, 'npmrank.json'), 'utf8'
	catch exception
		data = await request.get dataSource
		try
			JSON.parse data # Ensure this is valid JSON before writing it
			await fs.writeFile path.join(cacheFolder, 'npmrank.json'), data
	data = JSON.parse data
	Object.keys(data.rank).sort (a, b) ->
		parseFloat(data.rank[b]) - parseFloat(data.rank[a])


# Get the package.json file for the requested package, either from our cache or from the NPM registry (and cache it)
getPackageMetadata = (packageName) ->
	metadataFilename = "#{filenamify packageName.toLowerCase()}.json"
	try
		metadata = await fs.readFile path.join(metadataCacheFolder, metadataFilename), 'utf8'
		try
			metadata = JSON.parse metadata
		catch parseException
			console.error "Error parsing #{metadataFilename}"
			try
				await fs.unlink path.join(metadataCacheFolder, metadataFilename)
	catch readException
		throw readException unless readException.code is 'ENOENT'
		try
			metadata = await packageJson packageName,
				fullMetadata: yes
			await fs.writeFile path.join(metadataCacheFolder, metadataFilename), JSON.stringify(metadata)
	metadata


module.exports = ({ limit = 1000, useCache = yes } = {}) ->
	return new Promise (resolve) ->
		await del(cacheFolder) unless useCache
		await createCacheFolders()
		allPackages = await getListOfNpmPackages(useCache)
		packages = allPackages[0..limit]

		# Use an async queue to return package metadata concurrently, fetching up to 20 packages at once
		metadataCollection = {}
		fetchQueue = queue (packageName, callback) ->
			getPackageMetadata(packageName).then((data) ->
				metadataCollection[packageName] = data
			).then callback
		, 20

		# Once all the requested metadata has been retrieved, return it
		fetchQueue.drain = ->
			# Rearrange into a sorted array; some packages lack package.json files for various reasons, so exclude them
			resolve (metadataCollection[packageName] for packageName in packages when metadataCollection[packageName])

		for packageName in packages
			fetchQueue.push packageName
