// config/azureBlob.config.js
const { BlobServiceClient } = require('@azure/storage-blob');
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

const AZURE_STORAGE_CONNECTION_STRING = process.env.AZURE_STORAGE_CONNECTION_STRING;
const CONTAINER_NAME = process.env.CONTAINER_NAME || 'images';

const blobServiceClient = BlobServiceClient.fromConnectionString(AZURE_STORAGE_CONNECTION_STRING);
const containerClient = blobServiceClient.getContainerClient(CONTAINER_NAME);

const storage = multer.memoryStorage();
const upload = multer({ storage });

async function uploadToAzureBlob(file) {
    const blobName = uuidv4() + path.extname(file.originalname);
    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
    await blockBlobClient.uploadData(file.buffer, {
        blobHTTPHeaders: { blobContentType: file.mimetype }
    });
    return blockBlobClient.url;
}

module.exports = { upload, uploadToAzureBlob };
