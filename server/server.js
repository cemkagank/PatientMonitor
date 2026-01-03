import { ReadlineParser } from "@serialport/parser-readline";
import cors from "cors";
import express from "express";
import { SerialPort } from "serialport";

const app = express();
app.use(cors());

let state = {
  posture: "OFF",
  pressure: 0,
  battery: 0,
  alert: null,
  system: "OFF"
};

// 🔴 PORTU KONTROL ET
const port = new SerialPort({
  path: "COM3", // macOS: /dev/tty.usbserial-xxx
  baudRate: 9600
});

const parser = port.pipe(new ReadlineParser({ delimiter: "\n" }));

parser.on("data", (line) => {
  line = line.trim();
  console.log(line);

  const parts = line.split(",");

  if (parts[0] === "DATA") {
    state.posture  = parts[1];
    state.pressure = parseFloat(parts[2]);
    state.battery  = parseFloat(parts[3]);
  }

  if (parts[0] === "ALERT") {
    state.alert = parts.slice(1).join(",");
  }

  if (parts[0] === "EVENT") {
    state.system = parts[1];
  }
});

app.get("/data", (req, res) => {
  res.json(state);
});

app.listen(3000, () => {
  console.log("Server hazır : http://localhost:3000/data");
});