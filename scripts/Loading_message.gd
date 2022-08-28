extends Label


# Fake messages
const MESSAGES = [
	"Loading textures",
	"Ignoring bugs",
	"Blocking updates",
	"Generating project data",
	"Connecting external services",
	"Removing cache files",
	"Disconnecting asset store",
	"Updating user agreement",
	"Validating authentication",
	"Encrypting profile keys",
	"Uploading data collection",
	"Revoking licenses",
	"Purshasing subscription",
	"Accepting subscription payment",
	"Enforcing NFT plugins",
	"Oveheating cpu usage",
	"Disconnecting customer support",
	"Ingoring disk space left",
	"Exhausting internal memeory",
	"Updating privacy police",
	"Creating git conflicts",
	"Downloading large database",
]

var messages_list = MESSAGES.duplicate()

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	$Timer.connect("timeout", self, "handle_timeout")
	$Timer.start(0.8)

func handle_timeout():
	if messages_list.empty():
		messages_list = MESSAGES.duplicate()
	text = messages_list.pop_at(randi() % messages_list.size()) + "..."
	
