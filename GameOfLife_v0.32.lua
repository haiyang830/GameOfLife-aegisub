--[[
细胞自动机 ver 0.32 @haiyang

一行 code once放config表
一行 code once放函数
一行 template line notext : !gameOfLife(config[,world_name])!

config表可选配置项可以不填，将由configCheck函数生成默认值

不指定自定义世界默认为随机世界
如指定自定义世界需注意的是 世界的初始坐标是1,1 即显示在世界的左上角
自定义地图的方式为：
custum = {
	worldName1={x坐标, y坐标, x坐标, y坐标, ... },
	worldName2={x坐标, y坐标, x坐标, y坐标, ... },
	...
	},


更多关于细胞组合可生成的动画效果，可以看看wiki或者贴吧
https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
https://tieba.baidu.com/p/4423464677
--]]

--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


config = { 
-----------------主要配置项-----------------

t = {s=0,e=2000}, --设置开始/结束时间

size = {x=3,y=3}, --设置地图大小

distance = {x=10,y=10}, --设置细胞间距距离（一般与图形边界框的大小一致）

speed = 100, --设置细胞迭代速度（毫秒）

shape = { --设置细胞生存/死亡的图形
	live="m 0 0 l 10 0 10 10 0 10",
	die="m 0 0 l 10 0 10 10 0 10"
	},
-----------------可选配置项-----------------
--[[
pos = {x=0,y=0}, --设置地图生成坐标（默认为左上角 0,0 调整此项目可移动世界与屏幕的相对位置）

border = 3, --设置地图边界距离（地图边界外为不显示的部分，但迭代时参与计算，一般默认即可，如有问题可以加大边界距离试试）

state = "die", --设置输出细胞类型为die（相当于反向输出细胞）

mode = "reverse", --设置为逆向迭代

rule = {live=3,invariant=2}, --设置游戏规则 使细胞更容易存活或死亡（live：如果周围细胞数等于3 那么继续存活或使死亡细胞复活。invariant：如果周围细胞数等于2 那么细胞状态不变。其他情况则细胞死亡。默认live=3,invariant=2）

custum={ --设置自定义地图（地图定义方式如下且坐标从1,1开始计算）
	test1={10,10,11,10,12,9,12,11,13,10,14,10,15,10,16,10,17,9,17,11,18,10,19,10},
	test2={2,6,2,7,3,6,3,7,12,6,12,7,12,8,13,5,13,9,14,4,14,10,15,4,15,10,16,7,17,5,17,9,18,6,18,7,18,8,19,7,22,4,22,5,22,6,23,4,23,5,23,6,24,3,24,7,26,2,26,3,26,7,26,8,36,4,36,5,37,4,37,5},
	},

offset = {x=0,y=0}, --设置自定义地图相对于世界的偏移值（offset相对于pos参数，前者是移动指定地图与世界的相对位置，后者是移动世界与屏幕的相对位置）
--]]
}

--////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--外部函数调用
local coroutine = _G.coroutine
local ipairs = _G.ipairs
local pairs = _G.pairs
local assert = _G.assert
local type = _G.type
local setmetatable = _G.setmetatable
local getmetatable = _G.getmetatable
local aegisub_progress_set = _G.aegisub.progress.set
local aegisub_debug_out = _G.aegisub.debug.out

--检查配置数据
function configCheck(config,world_name)
	--主要配置检查（必填值）
	assert(config,"table 'config' not found!")
	assert(config.t,"table 'config.t' not found!")
	assert(config.size,"table 'config.size' not found!")
	assert(config.speed,"table 'config.speed' not found!")
	assert(config.shape,"table 'config.shape' not found!")
	assert(config.distance,"table 'config.distance' not found!")
	if world_name then assert(config.custum[world_name],"table 'config.custum."..world_name.."' not found!") end
	--可选配置检查
	if not config.pos then config.pos = {x=0,y=0} end
	if not config.border then config.border = 2 end
	if not config.pos then config.pos = {x=0,y=0} end
	if not config.offset then config.offset = {x=0,y=0} end
	if not config.rule then config.rule = {live=3,invariant=2} end
	--配置数值修正（防止小数点及负值）
	local function floor_abs(num)
		return math.abs(math.floor(num))
	end
	config.size.x = floor_abs(config.size.x)
	config.size.y = floor_abs(config.size.y)
	config.border = floor_abs(config.border)
	config.rule.live = floor_abs(config.rule.live)
	config.rule.invariant = floor_abs(config.rule.invariant)
	config.offset.x = math.floor(config.offset.x)
	config.offset.y = math.floor(config.offset.y)
	if config.border == 0 then config.border = 1 end --边界为0时 无法参与迭代 最小为 1
	--世界大小修正（世界大小小于定义地图所需大小时 自动扩大世界）
	if world_name then
		local max_num_x,max_num_y = 0,0
		for i=1,#config.custum[world_name],2 do
			if config.custum[world_name][i] > max_num_x then
				max_num_x = config.custum[world_name][i]
			end
			if config.custum[world_name][i+1] > max_num_y then
				max_num_y = config.custum[world_name][i+1]
			end
		end
		if max_num_x > config.size.x then
			config.size.x = max_num_x + 2
		end
		if max_num_y > config.size.y then
			config.size.y = max_num_y + 2
		end
	end
end
--表深拷贝
function cloneTable(object)
    local lookup_table = {}
    local function copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[copy(key)] = copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return copy(object)
end
--用于初始化世界，可自定义世界
function createWorld(config,world_name)
	local world = {}
	if world_name then --如果自定义地图则创建一个空地图
		for y=1 - config.border,config.size.y + config.border do
			world[y] = {}
			for x=1 - config.border,config.size.x + config.border do
				world[y][x] = 0 
			end
		end
		for i=1,#config.custum[world_name],2 do --读取自定义世界并写入表（世界的初始坐标是1,1开始）
			local x = config.custum[world_name][i] + config.offset.x
			local y = config.custum[world_name][i+1] + config.offset.y
			world[y][x] = 1
		end
	else --默认世界类型为随机
		for y=1 - config.border,config.size.y + config.border do
			world[y] = {}
			for x=1 - config.border,config.size.x + config.border do
				world[y][x] = math.random(0,1) --生成随机地图
			end
		end
	end
	--[[
	  x_table   x_table   x_table
	{{0,0,0,0},{1,1,1,1},   ...    } <-- world
	--]]
	return world
end
--用于迭代细胞
evolution = coroutine.create(
	function (config,world_name)
		local world = createWorld(config,world_name) --第一次运行则先创建世界
		local world_tmp = {}
		while true do
			coroutine.yield(world)
			for y=1 - config.border + 1,config.size.y + config.border - 1 do
				world_tmp[y] = {}
				for x=1 - config.border + 1,config.size.x + config.border - 1 do
					sum =
						world[y-1][x-1] + world[y-1][x] + world[y-1][x+1] +
						world[y][x-1]  			+			world[y][x+1] +
						world[y+1][x-1] + world[y+1][x] + world[y+1][x+1]
					if (sum == config.rule.live) then --如果周围细胞数等于3 那么继续存活或使死亡细胞复活
						world_tmp[y][x] = 1
					elseif (sum == config.rule.invariant) then --如果周围细胞数等于2 那么细胞状态不变
						world_tmp[y][x] = world[y][x]
					else
						world_tmp[y][x] = 0 --如果为其他（过于拥挤或过于稀少）细胞死亡
					end
				end
			end
			--将迭代后的地图赋值给当前地图
			for y=1 - config.border + 1,config.size.y + config.border - 1 do
				for x=1 - config.border + 1,config.size.x + config.border - 1 do
					world[y][x] = world_tmp[y][x]
				end
			end
		end
	end
)
--输出世界中每个存活/死亡细胞的坐标与时间
outPutCell = coroutine.create(
	function (config,evolution_all,evolution_times,state,mode)
		local function outPutPos(i,auto_i,key_s,key_y,key_x,val_x,state) --检测到相符的细胞类型则返回坐标
			if val_x == state then
				local pos_y = config.pos.y + config.distance.y * (key_y-1) --计算x坐标
				local pos_x = config.pos.x + config.distance.x * (key_x-1) --计算y坐标
				local time_s = config.t.s + (auto_i(i,key_s) - 1) * config.speed --计算retime开始时间
				local time_e = config.t.s + (auto_i(i,key_s) - 1) * config.speed + config.speed --计算retime结束时间
				coroutine.yield(pos_x,pos_y,time_s,time_e)
			end
		end
		local key_s,key_e,step,auto_i
		local function outPutMode(mode) --正序/倒序输出模式判断
			if mode == "reverse" then
				key_s = evolution_times
				key_e = 1
				step = -1
				return
					function (i,key) --倒序模式使i依然为正向
						return key - i + 1
					end
			elseif mode == "Positive" then
				key_s = 1
				key_e = evolution_times
				step = 1
				return
					function (i,key)
						return i
					end
			end
		end
		auto_i = outPutMode(mode)
		for i=key_s,key_e,step do
			local world = evolution_all[i]
			for key_y=1,config.size.y do
				local val_y = world[key_y]
				for key_x=1,config.size.x do
					local val_x = val_y[key_x]
					outPutPos(i,auto_i,key_s,key_y,key_x,val_x,state)
				end
			end
		end
	end
)
--生命游戏主函数
GoL = coroutine.create(
	function (config,world_name)
		local evolution_times = math.floor( (config.t.e - config.t.s)/config.speed ) --计算单位时间内的迭代次数
		local evolution_all = {} --用于存放所有迭代结果
		local evolution_qty = {live={},die={},live_all=0,die_all=0} --用于存放每次迭代生存/死亡数量及所有数量
		for i=1,evolution_times do --开始迭代所有细胞放入缓存表 计算每次迭代生存/死亡数量
			local _,world = coroutine.resume(evolution,config,world_name)
			--计算生存/死亡数量
			evolution_qty.live[i] = 0
			evolution_qty.die[i] = 0
			for key_y=1,config.size.y do
				local val_y = world[key_y]
				for key_x=1,config.size.x do
					local val_x = val_y[key_x]
					if val_x == 1 then
						evolution_qty.live[i] = evolution_qty.live[i] + 1 --每世界生存数量
						evolution_qty.live_all = evolution_qty.live_all + 1 --计算生存总数
					elseif val_x == 0 then
						evolution_qty.die[i] = evolution_qty.die[i] + 1 --每世界死亡数量
						evolution_qty.die_all = evolution_qty.die_all + 1 --计算死亡总数
					end
				end
			end
			--深拷贝表并赋值
			evolution_all[i] = cloneTable(world)
		end
		local state,state_str,mode,loops,shape
		local function stateCheck(config) --输出细胞输出类型/模式判断
			if config.state == "die" then --输出类型
				state = 0
				state_str = "die"
				loops = evolution_qty.die_all
				shape = config.shape.die
			else
				state = 1
				state_str = "live"
				loops = evolution_qty.live_all
				shape = config.shape.live
			end
			if config.mode == "reverse" then --输出模式
				mode = "reverse"
			else
				mode = "Positive"
			end
		end
		stateCheck(config)
		local qty_tmp = 0
		for times,qty in ipairs(evolution_qty[state_str]) do --计算实际需要的迭代次数
			qty_tmp = qty_tmp + qty
			if qty_tmp == evolution_qty[state_str.."_all"] then
				evolution_times = times	--实际迭代次数
				break
			end
		end
		--aegisub auto4 function
		maxloop(loops) --执行maxloop 循环数量为细胞存活/死亡总数
		for i=1,evolution_times do
			for loops=1,evolution_qty[state_str][i] do --以细胞存活/死亡数量来输出字符串
				local _,pos_x,pos_y,time_s,time_e = coroutine.resume( --调用细胞输出线程
					outPutCell,
					config,
					evolution_all,
					evolution_times,
					state,
					mode
					)
				--aegisub auto4 function
				retime("set",time_s,time_e) --retime时间控制
				local progress_percent = i/evolution_times*100 --用于输出生成进度
				coroutine.yield(pos_x,pos_y,shape,progress_percent)
			end
		end

	end
)
--生命游戏，可自定义世界
--gameOfLife(config[,world_name])
function gameOfLife(config,world_name)
	configCheck(config,world_name) --配置文件检查
	local _,pos_x,pos_y,shape,progress_percent = coroutine.resume(GoL,config,world_name) --执行迭代细胞线程
	--进度输出
	aegisub_progress_set(progress_percent) --aegisub auto4 function
	aegisub_debug_out("\n CreateWorld "..progress_percent.."% ...") --aegisub auto4 function
	--连接字符串
	local str =
		"{"..
		"\\an7"..
		"\\pos("..pos_x..","..pos_y..")"..
		"\\p1"..
		"}"..
		shape
	return str
end
