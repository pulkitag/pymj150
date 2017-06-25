import subprocess
import sys
import mujoco_py
import pytest
import os


def test_import_mujoco_py_as_cymj_with_shim():
    pip = 'pip3' if sys.executable.endswith('3') else 'pip'
    subprocess.check_call([pip, 'install', os.path.join('vendor', 'pymj_shim')])
    with pytest.warns(UserWarning):
        import pymj
        assert pymj.MjSim == mujoco_py.MjSim
