db.works.insertMany([
  { name: "Заміна мастила в двигуні", category: "ТО", price: 500 },
  { name: "Заміна масляного фільтра", category: "ТО", price: 150 },
  { name: "Заміна повітряного фільтра", category: "ТО", price: 100 }
])

//операція онолення
db.works.updateOne({ name: "Заміна мастила" }, { $set: { price: 550 } })

//операція знаходження($gt)
db.works.find({ price: { $gt: 500 } })

//операція знаходження($or)
db.works.find({
  $or: [
    { category: "ТО" },
    { price: { $lt: 600 } }
  ]
})

//виконання запиту для порівняння
db.works.find({ category: "ТО" }).explain("executionStats")

//executionTimeMillis: 4,
//totalKeysExamined: 0,
//totalDocsExamined: 3,

//створення індексу для works
db.works.createIndex({ category: 1, price: 1 })

//виконання запиту для порівняння
db.works.find({ category: "ТО" }).explain("executionStats")
    
//executionTimeMillis: 10,
//totalKeysExamined: 3,
//totalDocsExamined: 3,
//надиво executionTimeMillis виріс як і totalKeysExamined, а от totalDocsExamined залишився без змін

db.works.getIndexes()
//результати
//{ v: 2, key: { _id: 1 }, name: '_id_' },
//{ v: 2, key: { category: 1, price: 1 }, name: 'category_1_price_1' }