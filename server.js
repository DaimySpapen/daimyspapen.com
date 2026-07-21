import express from "express";
import path from "path";

const __dirname = import.meta.dirname

const app = express();

app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
    res.sendFile("index.html");
});

app.listen(8000, () => {
    console.log("Server running.");
});