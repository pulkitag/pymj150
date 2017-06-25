#!/usr/bin/env python3
from setuptools import find_packages, setup
from os.path import join, dirname, realpath
from setuptools.command.install import install

with open(join("mujoco_py", "version.py")) as version_file:
    exec(version_file.read())


class PostInstallCommand(install):
    """Post-installation for installation mode."""

    def run(self):
        install.run(self)
        import mujoco_py  # noqa


def read_requirements_file(filename):
    req_file_path = '%s/%s' % (dirname(realpath(__file__)), filename)
    with open(req_file_path) as f:
        return [line.strip() for line in f]


packages = find_packages()
# Ensure that we don't pollute the global namespace.
for p in packages:
    assert p == 'mujoco_py' or p.startswith('mujoco_py.')

setup(
    name='mujoco-py',
    version=__version__,  # noqa
    author='OpenAI Robotics Team',
    author_email='robotics@openai.com',
    url='https://github.com/openai/mujoco-py',
    packages=packages,
    include_package_data=True,
    install_requires=read_requirements_file('requirements.txt'),
    tests_require=read_requirements_file('requirements.dev.txt'),
    # Add requirements for mujoco_py/builder.py here since there's no
    # guarantee that they've been installed before this setup script
    # is run. (The install requirements only guarantee that those packages
    # are installed as part of installation. No promises about order.)
    setup_requires=['portalocker>=1.1.0', 'numpy>=1.11', 'Cython>=0.25.2'],
    cmdclass={
        'install': PostInstallCommand,
    },
)
