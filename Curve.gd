extends Line2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export var default_resolution = 10

var original_points
var resolution = default_resolution
var fourier_transform
var closed = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func change_res(direction):
	resolution = clamp(resolution + direction,1,200)
	points = reduce(original_points.duplicate(), floor(resolution))

func save_data():
	var p = []
	for i in range(len(points)):
		p.append([points[i].x, points[i].y])
	var save_dict = {
		"resolution" : resolution,
		"original_points" : p,
		"color" : [default_color[0],default_color[1],default_color[2],default_color[3]]
	}
	return save_dict

func load_data(data):
	resolution = data["resolution"]
	default_color = Color(data["color"][0], data["color"][1], data["color"][2], data["color"][3])
	original_points = []
	for i in range(len(data["original_points"])):
		original_points.append(Vector2(data["original_points"][i][0], data["original_points"][i][1]))
	change_res(0)

func close():
	add_point(points[0])
	pad()
	original_points = Array(points)
	change_res(0)
	closed = true

func is_closed():
	return closed

func pad():
	points = FFT_pad(points)

func move(d):
	fourier_transform[0] += d
	change_res(0)

func scale_by(factor):
	for i in range(1, len(fourier_transform)):
		fourier_transform[i] *= factor
	change_res(0)

func rotate_by(deg):
	for i in range(1, len(fourier_transform)):
		var f = Vector2(cos(deg2rad(deg)), sin(deg2rad(deg)))
		fourier_transform[i] = cmult(fourier_transform[i], f)
	change_res(0)

func FFT(X): #ONLY WORKS ON LISTS OF LENGTH POWER OF 2
	var n = len(X)
	var omega = -2*PI/n
	var xk
	var wk
	if n > 1:
		var even = []
		var odd = []
		for i in range(0,n,2):
			even.append(X[i])
			odd.append(X[i+1])
		X = FFT(even) + FFT(odd)
		for k in range(n/2):
			wk = Vector2(cos(k * omega), sin(k * omega))
			xk = X[k]
			X[k] = xk + cmult(wk, X[k+n/2])
			X[k+n/2] = xk - cmult(wk, X[k+n/2])
		for i in range(n):
			X[i] = X[i]/2
	return X

func IFFT(X): #ONLY WORKS ON LISTS OF LENGTH POWER OF 2
	var n = len(X)
	var omega = 2*PI/n
	var xk
	var wk
	if n > 1:
		var even = []
		var odd = []
		for i in range(0,n,2):
			even.append(X[i])
			odd.append(X[i+1])
		X = IFFT(even) + IFFT(odd)
		for k in range(n/2):
			wk = Vector2(cos(k * omega), sin(k * omega))
			xk = X[k]
			X[k] = xk + cmult(wk, X[k+n/2])
			X[k+n/2] = xk - cmult(wk, X[k+n/2])
	return X

func cmult(a,b): 
	return Vector2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x)

func FFT_pad(points):
	var length = 0
	for i in range(len(points) - 1):
		length += dist(points[i], points[i + 1])
	var ideal_len = 1
	while ideal_len < len(points) * 4 - 1:
		ideal_len *= 2
	ideal_len = min(1024,ideal_len)
	var ideal_dist = length / ideal_len
	var new_points = [points[0]]
	var pos = 0
	var index = 0
	var next_sample = ideal_dist
	while true:
		var p2 = points[index + 1]
		var p1 = points[index]
		var next_pos = pos + dist(p1, p2)
		while next_sample <= next_pos:
			var alpha = (next_sample - pos) / (next_pos - pos)
			new_points.append((1-alpha) * p1 + alpha * p2)
			if len(new_points) >= ideal_len:
				new_points.append(points[0])
				return new_points
			next_sample += ideal_dist
		pos = next_pos
		index += 1

func dist(p1,p2):
	return (p1 - p2).length()

func reduce(points, n_coeffs):
	var transform
	if fourier_transform:
		transform = fourier_transform.duplicate()
	else:
		var points2 = Array(points)
		points2.remove(len(points2) - 1)
		transform = FFT(points2)
		fourier_transform = transform.duplicate()
	var transform_index = []
	for i in range(len(transform)):
		transform_index.append([transform[i],i])
	transform_index.sort_custom(self, "FFT_comp")
	for i in range(n_coeffs + 1,len(transform_index)):
		if transform_index[i][1] != 0:
			transform[transform_index[i][1]] = Vector2(0,0)
	var result = IFFT(transform)
	return result + [result[0]]

func FFT_comp(a,b):
	return a[0].length() > b[0].length()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
