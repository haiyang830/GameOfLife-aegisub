# GameOfLife-aegisub
aegisub template

aegisub细胞自动机模版

需要先配置config表

主要配置项： 
    t 设置开始/结束时间 
    size 设置地图大小 
    distance 设置细胞间距距离 
    speed 设置细胞迭代速度 
    shape 设置细胞生存/死亡的图形 

可选配置项： 
    pos 设置地图生成坐标 
    border 设置地图边界距离 
    state 设置输出细胞类型为die 
    mode 设置为逆向迭代 
    custum 设置自定义地图 
    offset 设置自定义地图相对于世界的偏移值 

具体用法说明详见lua文件与test.ass
