extends RefCounted
class_name ShiftStory

const NOTES = [
	["02:17 / under the till", "HE DOESN'T MAKE THE RULES.\nTHE STORE DOES.\n\nThe milk used to have an ordinary name.\nWatch it when you aren't touching it.\n                         — M. Voss"],
	["02:48 / behind the fuse box", "The camera clock runs ahead.\nYour reflection should not.\n\nThe people outside have waited years.\nDo not let a familiar uniform decide for you.\n                         — M. Voss"],
	["03:02 / folded into a mop bucket", "The marks on the stockroom door are useful.\nThe printed instructions are sometimes useful.\nThose aren't the same thing.\n\nI counted three empty frames on the board.\nThey called them safety points."],
	["03:33 / a receipt, still warm", "Camera 4 isn't broken.\nHe doesn't want you to see the front exit.\n\nSome rules protect us.\nSome rules protect the building.\nI still can't tell which is which."],
	["04:06 / your own handwriting?", "If the telephone asks for your name,\nDO NOT LEND IT YOURS.\n\nYou owe a shift. You do not owe yourself.\nTell it when your shift ends.\n                         — M. Voss"],
	["04:41 / inside an empty uniform", "The badge is real.\nALEX / EMPLOYEE 0417.\n\nThe signatures on this page aren't.\nThe manager's photograph never gets older.\nThe people in the other frames do."],
	["05:12 / taped over a printed rule", "Do not open the BACK door.\nThat one was true.\n\nAt six, use the FRONT.\nIf the glass is full of faces,\nyou are on the correct side."],
	["05:49 / beside the time clock", "Sign ALEX. Confirm 0417.\nTake only your remaining time.\n\nThe telephone can ring.\nThe monitor can ask.\nYour shift ends at six."]
]

static func phase(index: int, count: int) -> String:
	var fraction = float(index) / maxf(count - 1, 1)
	if fraction < 0.20: return "I / NORMAL OPERATIONS"
	if fraction < 0.40: return "II / SOMETHING IS OFF"
	if fraction < 0.64: return "III / CONFLICTING INSTRUCTIONS"
	if fraction < 0.94: return "IV / THE STORE REMEMBERS"
	return "V / 5:59 AM"

static func clock_label(index: int, count: int) -> String:
	var minute = int(359.0 * float(index) / maxf(count - 1, 1))
	var hour = minute / 60
	return "%d:%02d AM" % [12 if hour == 0 else hour, minute % 60]
