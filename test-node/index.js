const express = require("express");

const app = express();

app.use((req, res, next) => {
  console.log({
    time: Date.now(),
    url: req.url,
    method: req.method,
    params: req.query,
    headers: req.headers,
  });
  next();
});

app.get("/health", (req, res) => {
  res.json({
    status: "ok",
  });
});

app.listen(3007);
