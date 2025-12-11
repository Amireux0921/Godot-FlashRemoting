class_name DateTime
extends RefCounted # 继承RefCounted，支持对象管理

# 核心存储：Godot标准的datetime字典（包含year/month/day/hour/minute/second等字段）
var value: Dictionary = {}

# 核心属性：Unix时间戳（秒级，兼容标准Unix时间戳）
var timestamp: float:
	get:
		# 空值保护：无时间字典时返回当前时间戳
		if value.is_empty():
			
			return Time.get_unix_time_from_system()
		# 转换datetime字典为Unix秒级时间戳
		#
		return Time.get_unix_time_from_datetime_dict(value) * 1000
	set(new_timestamp):
		# 处理毫秒级时间戳（13位）→ 转换为秒级（10位）
		var ts = new_timestamp if new_timestamp < 1e12 else new_timestamp / 1000.0
		# 转换时间戳为datetime字典（UTC基准）
		value = Time.get_datetime_dict_from_unix_time(ts)
		# 可选：修正为北京时间（UTC+8，按需开启）
		#_adjust_timezone(8)



# ===================== 核心静态方法 =====================
# 获取当前时间的DateTime实例（自动适配系统时区）
static func Now() -> DateTime:
	var dt = DateTime.new()
	# 正确获取系统当前时间的datetime字典（带时区）
	dt.value = Time.get_datetime_dict_from_system(true)
	return dt

# 从Unix时间戳创建DateTime实例（支持秒级/毫秒级）
static func From(timestamp: float) -> DateTime:
	var dt = DateTime.new()
	dt.timestamp = timestamp # 调用setter自动转换
	return dt

# ===================== 实用工具方法 =====================
# 时区修正（如北京时间+8，负数为西时区）
func _adjust_timezone(hours_offset: int):
	if value.is_empty():
		return
	# 计算总分钟偏移（避免跨天/跨月/跨年问题）
	var total_minutes = value["hour"] * 60 + value["minute"] + hours_offset * 60
	# 转换为小时/分钟，自动处理进位
	var new_hour = (total_minutes / 60) % 24
	var new_minute = total_minutes % 60
	# 处理跨天（小时为负/超24）
	var day_offset = (total_minutes / 60) / 24
	if day_offset != 0:
		# 调用Godot原生方法计算偏移后的日期
		value = Time.get_datetime_dict_from_unix_time(timestamp + day_offset * 86400.0)
	# 赋值修正后的小时/分钟
	value["hour"] = new_hour
	value["minute"] = new_minute

# 格式化输出（自定义格式，支持常用模板）
# 示例格式："YYYY-MM-DD HH:mm:ss" → 2025-07-12 15:30:45
func format(fmt: String = "YYYY-MM-DD HH:mm:ss") -> String:
	if value.is_empty():
		return ""
	# 映射自定义格式到Godot原生格式符
	var fmt_map = {
		"YYYY": "%Y", # 4位年
		"MM": "%m",   # 2位月
		"DD": "%d",   # 2位日
		"HH": "%H",   # 24小时制小时
		"hh": "%I",   # 12小时制小时
		"mm": "%M",   # 2位分钟
		"ss": "%S",   # 2位秒
		"WW": "%A",   # 星期全称（如Monday）
		"ww": "%a"    # 星期简称（如Mon）
	}
	# 替换自定义格式符为Godot原生格式
	var godot_fmt = fmt
	for k in fmt_map:
		godot_fmt = godot_fmt.replace(k, fmt_map[k])
	# 转换为格式化字符串
	return Time.get_datetime_string_from_datetime_dict(value, godot_fmt)

# ===================== 基础方法 =====================
# 字符串化（默认返回北京时间格式）
func _to_string() -> String:
	# 先修正为北京时间（UTC+8）
	#_adjust_timezone(8)
	# 返回带时区的标准格式：2025-07-12 15:30:45 (CST)
	return Time.get_datetime_string_from_datetime_dict(value,true)

# 比较方法：是否晚于另一个DateTime
func is_after(other: DateTime) -> bool:
	return self.timestamp > other.timestamp

# 比较方法：是否早于另一个DateTime
func is_before(other: DateTime) -> bool:
	return self.timestamp < other.timestamp

# 比较方法：是否相等
func is_equal(other: DateTime) -> bool:
	return abs(self.timestamp - other.timestamp) < 1.0 # 误差1秒内视为相等
