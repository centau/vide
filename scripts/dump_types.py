import requests

enable_formatting = True
new_line = ";"
next_entry = ";"
new_line_not_required = ""
indent = ""
space = ""

if enable_formatting:
	new_line = "\n"
	new_line_not_required = "\n"
	space = " "
	next_entry = ",\n"
	indent = "\t"

compile_for_all_classes = False
desired_classes = [
	"CanvasGroup",
	"Frame",
	"ImageButton",
	"TextButton",
	"ImageLabel",
	"TextLabel",
	"ScrollingFrame",
	"TextBox",
	"VideoFrame",
	"ViewportFrame",
	"BillboardGui",
	"ScreenGui",
	"AdGui",
	"SurfaceGui",
	"SelectionBox",
	"BoxHandleAdornment",
	"ConeHandleAdornment",
	"CylinderHandleAdornment",
	"ImageHandleAdornment",
	"LineHandleAdornment",
	"SphereHandleAdornment",
	"WireframeHandleAdornment",
	"ParabolaAdornment",
	"SelectionSphere",
	"ArcHandles",
	"Handles",
	"SurfaceSelection",
	"Path2D",
	"UIAspectRatioConstraint",
	"UISizeConstraint",
	"UITextSizeConstraint",
	"UICorner",
	"UIDragDetector",
	"UIFlexItem",
	"UIGradient",
	"UIListLayout",
	"UIGridLayout",
	"UIPageLayout",
	"UITableLayout",
	"UIPadding",
	"UIScale",
	"UIStroke",

	"WorldModel",
	"Camera",
	"Part",
	"Model",
	"MeshPart",
	"Highlight"
]

lines_before = [
	"type p<T> ="+space+"T?|()->T",
	"type e<T=()->()> ="+space+"T?",
	"type a={priority:"+space+"number,"+space+"callback:"+space+"(Instance)"+space+"->"+space+"()}",
	"type recursive<T> =T|{recursive<T>}"
	"type c<T> =a|T|Recursive<Instance>|()->Recursive<Instance>",
	"type ContentId = string", # temporary
	"type Dictionary = {[string]: any}",
	"type Array = {any}"
]

lines_after = [
	"return{}"
]

lines = []

API_DUMP_LINK = "https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json"
CORRECTIONS_LINK = "https://raw.githubusercontent.com/NightrainsRbx/RobloxLsp/master/server/api/Corrections.json"

api_dump_request = requests.get(API_DUMP_LINK)
corrections_dump_request = requests.get(CORRECTIONS_LINK)

api_dump = api_dump_request.json()
corrections_dump = corrections_dump_request.json()

aliases = {
	"int64": "number",
	"int": "number",
	"float": "number",
	"double": "number",
	"bool": "boolean",
	"Content": "string",
	"string": "string"+space+"|"+space+"number",
	"OptionalCoordinateFrame": "CFrame?",
	"BinaryString": "string",
}

map_corrections = {}
map_roblox_classes = {}

for roblox_class in api_dump["Classes"]:
	map_roblox_classes[roblox_class["Name"]] = roblox_class

for correction_class in corrections_dump["Classes"]:
	map_corrections[correction_class["Name"]] = correction_class

def get_prop_type(value_type):

	prop = ""

	match value_type["Category"]:
		case "Enum":
			prop = "Enum." + value_type["Name"]
		case "Class":
			prop = value_type["Name"] + "?"
		case "Primitive":
			value_name = value_type["Name"]
			prop = aliases.get(value_name) or value_name
		case "DataType":
			value_name = value_type["Name"]
			prop = aliases.get(value_name) or value_name
		case "Group":
			prop = value_type["Name"]

	# Map value types

	return prop

def append_class(roblox_class):
	#lines.append("\t-- " + roblox_class["Name"])
	correction_class = map_corrections.get(roblox_class["Name"]) or {"Members": []}
	correction_members_map = {}

	for member in correction_class["Members"]:
		correction_members_map[member["Name"]] = member
	
	for member in roblox_class["Members"]:
		if (member.get("Tags") and "ReadOnly" in member["Tags"]) == True: continue
		if (member.get("Tags") and "Deprecated" in member["Tags"]) == True: continue
		if (member.get("Tags") and "NotScriptable" in member["Tags"]) == True: continue
		
		# We check if it's a property and if it is, run the get_prop_type function.
		if member["MemberType"] == "Property":
			if member["Security"]["Write"] != "None": continue
			
			if "Deprecated" in member: continue

			lines.append(indent+member["Name"] + ":"+space+"p<" + get_prop_type(member["ValueType"]) + ">"+next_entry)
		elif member["MemberType"] == "Event":
			if member["Security"] != "None": continue

			correction_member = correction_members_map.get(member["Name"]) or {"Parameters": []}

			correction_parameters_map = {}
			for parameter in correction_member["Parameters"]:
				correction_parameters_map[parameter["Name"]] = parameter

			line = indent+member["Name"] + ":"+space+"e<("
			is_first = True
			for parameter in member["Parameters"]:

				correction_parameter = correction_parameters_map.get(parameter["Name"])
				
				if is_first == False:
					line += ","
				is_first = False


				if correction_parameter == None:
					value = get_prop_type(parameter["Type"])
					if value == "Tuple":
						line += "...any"
					else:
						line += parameter["Name"] + ":" + value
				else:
					line += parameter["Name"] + ":"
					name = correction_parameter["Type"].get("Name")
					generic = correction_parameter["Type"].get("Generic")

					if name != None:
						line += name
					elif generic != None:
						line += "{" + generic + "}"

			line += ")"+space+"->"+space+"()>"+next_entry
			lines.append(line)
	
	if roblox_class["Superclass"] != "<<<ROOT>>>":
		append_class(map_roblox_classes[roblox_class["Superclass"]])

if compile_for_all_classes:
	desired_classes = map_roblox_classes

for class_name in desired_classes:
	
	roblox_class = map_roblox_classes[class_name]

	if 'Tags' in roblox_class and "NotCreatable" in roblox_class['Tags']:
		continue
	name = roblox_class['Name']
	lines.append("export type v" + name + space + "="+space+"{"+new_line_not_required)
	append_class(roblox_class)
	lines.append(indent+"[number]:"+space+"c<v"+name+">"+new_line)
	lines.append(new_line_not_required+"}"+new_line)

with open("src/roblox_types.luau", "wt") as file:

	single_line = new_line.join(lines_before) + new_line + ''.join(lines) + new_line.join(lines_after)
	file.write(single_line)
	
	file.close()

with open("src/create.luau", "r") as reader:
	line_create_at = 0
	is_found = False
	lines = reader.readlines()
	for line in lines:
		line_create_at += 1
		if line.find("return (create") != -1:
			is_found = True
			break
	
	# We found the line we can start modifying from
	
	with open("src/create.luau", "w") as writer:
		
		# First write all the lines from 0 to line_create_at-1
		#lines = reader.readlines(100)
		writer.writelines(lines[:line_create_at])
		iterate_through = desired_classes
		first = True
		
		if compile_for_all_classes:
			iterate_through = map_roblox_classes
		
		for name in iterate_through:
			roblox_class = map_roblox_classes[name]
			# Skip unnecessary  classes
			if "Tags" in roblox_class and "NotCreatable"in roblox_class["Tags"]: continue
			if first:
				first = False
			else:
				writer.write("&")
			writer.write(f'\t( (class: "{name}") -> (r.v{name}) -> {name} )\n')
			

		writer.close()
		pass
	
	reader.close()
	
with open("src/init.luau", "r") as reader:
	line_create_at = 0
	is_found = False
	lines = reader.readlines()
	for line in lines:
		line_create_at += 1
		if line.find("-- TYPES HERE") != -1:
			is_found = True
			break
	
	# We found the line we can start modifying from
	
	with open("src/init.luau", "w") as writer:
		
		# First write all the lines from 0 to line_create_at-1
		#lines = reader.readlines(100)
		writer.writelines(lines[:line_create_at])
		lines_after = lines[line_create_at+1:]

		iterate_through = desired_classes
		first = True
		
		if compile_for_all_classes:
			iterate_through = map_roblox_classes
		
		for name in iterate_through:
			roblox_class = map_roblox_classes[name]
			# Skip unnecessary  classes
			if "Tags" in roblox_class and "NotCreatable"in roblox_class["Tags"]: continue
			if first:
				first = False
			writer.write(f'export type v{name} = roblox_types.v{name}\n')
			
	
		writer.writelines(lines_after)
		writer.close()
		pass
	
	reader.close()