from setuptools import setup

dependencies_base = [
    "numpy",
    "pandas",
    "xlrd",
]

dependencies_test = [
    "pytest",
    "pyyaml"
]

setup(
    name='neonatal_sleep',
    version='0.1',
    packages=['neonatal_sleep'],
    url='',
    license='',
    author='UCL RSDG',
    author_email='rc-softdev@ucl.ac.uk',
    description='',
    install_requires=dependencies_base,
    extras_require={
        "test": dependencies_test
    }
)
