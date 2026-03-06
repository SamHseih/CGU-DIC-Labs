### 筆記解析
- V0 版本為第一次撰寫，使用狀態機 + 9個clk 去做撰寫，耗費時間偏多
- V2 版本為第二次撰寫，使用Sliding Window 去做存取動作，若為開頭才會讀9個clk，若為非開頭則只要讀取 3 clk即可
    缺點: condition 使用 assign 做接線，非常危險，gatesim 會有問題
- V3 改善 V2版本，將condition 轉換為 sequential 撰寫