db.customers.insertMany([
  { name: "Олександр Іваненко", phone: "+380501112233", carModel: "Toyota Camry" },
  { name: "Марія Петренко", phone: "+380672223344", carModel: "Honda CR-V" },
  { name: "Іван Сидоренко", phone: "+380633334455", carModel: "BMW X5" }
])

//операція знаходження($in)
db.customers.find({ carModel: { $in: ["Toyota Camry", "BMW X5"] } })