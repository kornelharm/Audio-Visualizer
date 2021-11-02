extends Control

# Amount of bars displayed
export var BAR_COUNT = 17
# Maximum frequency analyzed
export var FREQ_MAX = 12000
# Width of the window
export var WINDOW_WIDTH = 1920
# Distance of bar from previous as a multiple of bar width
export var  BAR_SPACING: float = 1.2
# Width of bars with no gap
var WIDTH: float = WINDOW_WIDTH/BAR_SPACING
# Height of each bar
export var HEIGHT = 300
# Higher value scales for taller bars
export var MIN_VOLUME = 75.0
export var SMOOTH = 0.5
export var BASE_HEIGHT = 2
var BAR_COLOR:Color
onready var column_width: float = WIDTH/BAR_COUNT
export var ANIMATION_SPEED = 0.002
export(String, "Rainbow", "Rainbow Breathing", "White", "Rainbow Fade") var STYLE
export(String, "Modified Decibel", "Decibel") var SCALING
export(String, "Normal", "Right Bias") var FREQUENCY_BIAS
export(String, "Normal", "Mirrored") var MIRRORING
export var EXP_MODIFIER = 1.1
export var DECAY_MODIFIER = 0.5
export var DECAY_PERCENT = 0.9
var timer:float = 0
export var SCALED_VOLUME_MULTIPLIER = 0.5

var spectrum : AudioEffectInstance
var bars = []
var velocities = []
var colors = []
var decay_point = HEIGHT*DECAY_PERCENT

func initialize():
	# Sets the background of the window to transparent
	get_tree().get_root().set_transparent_background(true)
	# Sets the size of the window to the size of the visualizer
	OS.set_window_size(Vector2(WIDTH*BAR_SPACING,HEIGHT))
	# The Spectrum Analyzer object
	spectrum = AudioServer.get_bus_effect_instance(0,0)
	
	bars.clear()
	velocities.clear()
	colors.clear()
	# Create containers for bar heights and starting colors
	for i in range(0, BAR_COUNT):
		bars.append(0)
		velocities.append(0)
		colors.append(float(i)/BAR_COUNT)

# Called when the node enters the scene tree for the first time.
func _ready():
	initialize()


# Triggers refresh of visualizer
func _on_Timer_timeout():
	update()
	
func get_bar_color(bar_number):
	# Control color of bar depending on selected style
	var barColor:Color
	if(STYLE == "Rainbow Breathing"):
		barColor = Color.from_hsv(fmod(colors[bar_number]+timer,1), 1, 1)
	elif(STYLE == "Rainbow"):
		barColor = Color.from_hsv(colors[bar_number], 1, 1)
	elif(STYLE == "White"):
		barColor = Color.white
	elif(STYLE == "Rainbow Fade"):
		barColor = Color.from_hsv(fmod(colors[0]+timer,1), 1, 1)
	return barColor
	
func energy_of_bar(bar_number, min_freq, max_freq):
	var magnitude = spectrum.get_magnitude_for_frequency_range(min_freq, max_freq).length()
	var bar_volume = MIN_VOLUME
	if(FREQUENCY_BIAS == "Right Bias"):
				bar_volume = (bar_number*((MIN_VOLUME*SCALED_VOLUME_MULTIPLIER)/MIN_VOLUME))+MIN_VOLUME
				
	# Converts magnitude into a value between 0-1 to describe its volume
	return clamp((bar_volume + linear2db(magnitude)) / bar_volume, 0, 1)
	
func get_scaled_bar(bar_number):
	var final_height = pow(bars[bar_number], EXP_MODIFIER)
	if(final_height > decay_point):
		var decaydiff = final_height - decay_point
		final_height = decay_point + pow(decaydiff, DECAY_MODIFIER)
	return final_height
	

func _draw():
	# Controls animation as an offset
	timer += ANIMATION_SPEED
	
	# Starts from 0hz, represents lower bound of range analyzed
	var prev_freq = 20
	
	
	if(MIRRORING == "Normal"):
		# For each bar
		for i in range(0,BAR_COUNT):
			# Upper bound of range analyzed
			var freq = (i+1) * FREQ_MAX / BAR_COUNT
			
			var energy = energy_of_bar(i, prev_freq, freq)

			# Volume of current range
			var current_volume = energy * HEIGHT + BASE_HEIGHT
			var diff = current_volume - bars[i]
			velocities[i] = diff
			
			bars[i] += velocities[i] * max((diff/HEIGHT),SMOOTH)
			if(bars[i] < 0):
				bars[i] = 0
			
			var final_height
			if(SCALING == "Modified Decibel"):
				final_height = get_scaled_bar(i)
			else:
				final_height = bars[i]

			
			# Position bar
			var pos_x = column_width * i * BAR_SPACING
			var pos_y = HEIGHT - final_height
			
			# Control color of bar depending on selected style
			var barColor:Color = get_bar_color(i)
			
			# Draw bar	
			draw_rect(Rect2(Vector2(pos_x, pos_y), Vector2(column_width, final_height)), barColor)
			
			# Upper bound becomes lower bound for next bar
			prev_freq = freq
	else:
		for i in range(0,(BAR_COUNT/2)+1):
			# Upper bound of range analyzed
			var freq = (i+1) * FREQ_MAX / BAR_COUNT
			
			var energy = energy_of_bar(i, prev_freq, freq)

			# Volume of current range
			var current_volume = energy * HEIGHT + BASE_HEIGHT
			var diff = current_volume - bars[i]
			velocities[i] = diff		
			
			bars[i] += velocities[i] * max((diff/HEIGHT),SMOOTH)
			if(bars[i] < 0):
				bars[i] = 0
			
			var final_height
			if(SCALING == "Modified Decibel"):
				final_height = get_scaled_bar(i)
			else:
				final_height = bars[i]

			
			# Position bar
			var pos_x: float = column_width * i * BAR_SPACING
			var pos_y = HEIGHT - final_height
			var pos_x1 = column_width * (BAR_COUNT-i-1) * BAR_SPACING
			
			# Control color of bar depending on selected style
			var barColor:Color = get_bar_color(i)
			
			# Draw bar	
			draw_rect(Rect2(Vector2(pos_x, pos_y), Vector2(column_width, final_height)), barColor)
			draw_rect(Rect2(Vector2(pos_x1, pos_y), Vector2(column_width, final_height)), barColor)
			
			# Upper bound becomes lower bound for next bar
			prev_freq = freq
		
