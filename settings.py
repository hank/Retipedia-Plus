# This is the root path of where the Retipedia files are contained in the .nomadnetwork storage/pages folder.
# In this example config, if your Retipedia folder is under .nomadnetwork/storage/pages/Retipedia, then the root folder would be "Retipedia"
# You can adjust htis if you want it to point at somewhere else outside of the parent folder 
root_folder = "retipedia"

# Node settings
ascii_art_enabled = True # Do you want to print an ASCII splash at the top? (Can save a small amount of time on page load if set to "False")

node_title = "🬧 The NomadNet WikiCiv"

# The LXMF address of the Node operator - this is an optional field that can be toggled on / off to display on the about page
lxmf_address = False

# Path to the directory containing ZIM binary files.
# Meta sidecar files (.zim.meta) live in the zims/ subdirectory alongside the code.
# ZIM binaries can live anywhere — set this to wherever you store them.
zims_dir = "/space/retipedia/zims"

# Path to the directory containing EPUB books.
epubs_dir = "/space/retipedia/epubs"
