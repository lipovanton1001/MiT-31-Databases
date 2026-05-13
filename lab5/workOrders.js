db.workOrders.insertMany([

  { woNo: "WO01", customerPhone: "0501112233", date: new Date("2024-03-01"), items: [{ work: "Заміна мастила", qty: 1, price: 500 }], status: "Completed" },

  { woNo: "WO02", customerPhone: "0672223344", date: new Date("2024-03-02"), items: [{ work: "Комп'ютерна діагностика", qty: 1, price: 600 }], status: "Completed" },

  { woNo: "WO03", customerPhone: "0633334455", date: new Date("2024-03-03"), items: [{ work: "Заміна гальмівних колодок", qty: 2, price: 800 }], status: "In Progress" }

])

//операція видалення
db.workOrders.deleteOne({ woNo: "WO03" })

//операція знаходження($gte)
db.workOrders.find({ "items.qty": { $gte: 1 } })

//операція знаходження($and)
db.workOrders.find({
  $and: [
    { status: "Completed" },
    { date: { $gte: new Date("2024-03-01") } }
  ]
})

//---------------------------------лаб.5.2

//фільтруємо замовлення за останні 3 місяці($match)
db.workOrders.aggregate([
  { 
    $match: { 
      date: { $gte: new Date("2024-01-01"), $lte: new Date("2024-03-31") } 
    } 
  }
])

//групування замовлень за місяцем ($group)
db.workOrders.aggregate([
  {
    $group: {
      _id: { month: { $month: "$date" }, year: { $year: "$date" } },
      totalOrders: { $sum: 1 }
    }
  },
  { 
    $sort: { "_id.year": 1, "_id.month": 1 } 
  }
])

//сортування за сумою замовлення ($sort)
db.workOrders.aggregate([
  { $unwind: "$items" },
  { 
    $group: {
      _id: "$woNo",
      totalAmount: { $sum: { $multiply: ["$items.qty", "$items.price"] } },
      status: { $first: "$status" }
    }
  },
  { $sort: { totalAmount: -1 } }
])

//розгорнення масивів items у замовленнях($unwind)
db.workOrders.aggregate([
  { $unwind: "$items" },
  { $project: { woNo: 1, date: 1, workName: "$items.work", quantity: "$items.qty" } }
])

//підрахування кількості проданих одиниць послуг/товарів
db.workOrders.aggregate([
  { $unwind: "$items" },
  { 
    $group: {
      _id: "$items.work",
      totalSoldUnits: { $sum: "$items.qty" }
    }
  },
  { $sort: { totalSoldUnits: -1 } }
])

//отримуємо інформацію про клієнтів у замовленнях
db.workOrders.aggregate([
  {
    $lookup: {
      from: "customers",
      localField: "customerPhone",
      foreignField: "phone",
      as: "customerInfo"
    }
  },
  //розгортаємо масив, який створює lookup
  { $unwind: "$customerInfo" },
  { 
    $project: { 
      woNo: 1, 
      date: 1, 
      "customerInfo.name": 1, 
      "customerInfo.carModel": 1 
    } 
  }
])

//
db.workOrders.aggregate([
  { 
    $group: { 
      _id: "$customerPhone", 
      orderCount: { $sum: 1 } 
    } 
  },
  {
    $lookup: {
      from: "customers",
      localField: "_id",
      foreignField: "phone",
      as: "client"
    }
  },
  { $unwind: "$client" },
  { $sort: { orderCount: -1 } },
  { $limit: 3 }, // топ-3 найактивніших
  { $project: { clientName: "$client.name", orderCount: 1 } }
])

//перевіряємо продуктивність запиту
db.workOrders.explain("executionStats").aggregate([
  { $match: { status: "Completed" } },
  { $group: { _id: "$customerPhone", total: { $sum: 1 } } }
])

// створення індексу
db.workOrders.createIndex({ status: 1 })

// повторна перевірка продуктивності
db.workOrders.explain("executionStats").aggregate([
  { $match: { status: "Completed" } },
  { $group: { _id: "$customerPhone", total: { $sum: 1 } } }
])

//
