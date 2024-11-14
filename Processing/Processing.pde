import java.text.SimpleDateFormat;
import java.util.Calendar;

float pressure;
Table pressureData;
int numRows;
String fileName = "pressure_data.csv";
int maxRows = 10;  // 我們只繪製最新的10筆資料

void setup() {
  size(800, 600);
  
  // 初始化或讀取現有的 CSV 檔案
  pressureData = loadTable(fileName, "header");
  
  if (pressureData == null) {
    // 如果檔案不存在，則創建新的 Table 並添加標題
    pressureData = new Table();
    pressureData.addColumn("Time");
    pressureData.addColumn("Pressure (hPa)");
  }
  
  numRows = pressureData.getRowCount();
  println("Number of rows in CSV: " + numRows);
}

void draw() {
  background(255);
  
  // 獲取隨機壓力數值
  pressure = random(900, 1100);
  fill(0);
  textSize(32);
  text("Current Pressure: " + nf(pressure, 1, 2) + " hPa", 50, 50);
  
  // 繪製條形圖
  fill(map(pressure, 900, 1100, 0, 255), 0, 0);
  rect(50, 100, 100, pressure - 900);
  
  // 獲取當前時間，格式 yyyy/MM/dd HH:mm:ss
  String timeStamp = new SimpleDateFormat("yyyy/MM/dd HH:mm:ss").format(Calendar.getInstance().getTime());
  
  // 添加新的一行數據到 Table
  TableRow newRow = pressureData.addRow();
  newRow.setString("Time", timeStamp);
  newRow.setFloat("Pressure (hPa)", pressure);
  
  // 保存更新的 Table 到 CSV 檔案
  saveTable(pressureData, fileName);
  
  // 重新讀取 CSV 檔案數據，確保讀取的數據是最新的
  pressureData = loadTable(fileName, "header");
  numRows = pressureData.getRowCount();
  
  // 我們只關心最新的10筆數據
  int startRow = max(0, numRows - maxRows);  // 計算起始行數
  
  // 繪製 CSV 數據圖表，使用線條連接相鄰的數據點
  stroke(0);  // 設置線條顏色
  strokeWeight(2);  // 設置線條寬度
  
  for (int i = startRow + 1; i < numRows; i++) {
    float prevPressure = pressureData.getFloat(i - 1, "Pressure (hPa)");
    float currPressure = pressureData.getFloat(i, "Pressure (hPa)");
    
    // 計算每個點的位置
    float x1 = map(i - 1 - startRow, 0, maxRows, 200, width - 50);  // 限制 x 坐標在最新的10筆數據範圍內
    float y1 = map(prevPressure, 900, 1100, height - 50, 100);
    
    float x2 = map(i - startRow, 0, maxRows, 200, width - 50);  // 限制 x 坐標在最新的10筆數據範圍內
    float y2 = map(currPressure, 900, 1100, height - 50, 100);
    
    // 繪製兩點之間的連接線
    line(x1, y1, x2, y2);
  }
  
  delay(300);
}

void keyPressed() {
  // 當按下Q時退出程式
  if (key == 'Q' || key == 'q') {
    exit();  // 退出程式
  }
}
