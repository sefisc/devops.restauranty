const express = require('express');
const router = express.Router();

const Item = require('../models/Item.model')

const { upload, uploadToAzureBlob } = require('../config/azure.config');

router.get("/", (req, res) => {

    Item.find().then(items => {
        res.json(items)
    }).catch(err => {
        res.status(400).json(err)
    })

})

router.get("/:id", (req, res) => {

    const id = req.params.id

    Item.findById(id).then(items => {
        res.json(items)
    }).catch(err => {
        res.status(400).json(err)
    })

})

router.post("/", upload.single("imagem"), async (req, res) => {
    try {
        const itemData = req.body;
        let imageUrl = "";

        if (req.file) {
            imageUrl = await uploadToAzureBlob(req.file);
            itemData.image = [imageUrl];
        }

        const newItem = await Item.create(itemData);
        res.json(newItem);
    } catch (err) {
        res.status(400).json(err);
    }
});


router.put("/:id", upload.single("imagem"), async (req, res) => {
    try {
        const itemData = req.body;

        if (req.file) {
            const imageUrl = await uploadToAzureBlob(req.file);
            itemData.image = [imageUrl];
        }

        const updatedItem = await Item.findByIdAndUpdate(req.params.id, itemData, { new: true });
        res.json(updatedItem);
    } catch (err) {
        res.status(400).json(err);
    }
});



router.delete("/:id", (req, res) => {

    const id = req.params.id

    Item.findByIdAndDelete(id).then(itemDeleted => {
        res.json({
            message: "Item Eliminado",
            itemDeleted
        })
    }).catch(err => {
        res.status(400).json(err)
    })

})

module.exports = router;
