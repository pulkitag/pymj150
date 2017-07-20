# pymj150
This is based on Open AI's python wrappers

# Enabling GPU rendering 
We need `libOpenGL.so` and `libEGL.so.1`. These come with the nvidia drivers if not already found on the machine. 

Then `patchelf` needs to be installed. Use

```
git clone https://github.com/NixOS/patchelf.git
```
and follow instructions in the git repository to install it. 

`mujoco_py/builder.py` will assume that the `.so` files are present in `/usr/local/nvidia/lib64`.
Modify this path to point to where these files are present. Use `locate libOpenGL` to find the file. 
