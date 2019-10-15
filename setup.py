from setuptools import find_packages, setup

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
    packages=find_packages(),
    url='',
    license='',
    author='UCL RSDG',
    author_email='rc-softdev@ucl.ac.uk',
    description='',
    install_requires=dependencies_base,
    extras_require={
        "test": dependencies_test
    },
    entry_points={
        "console_scripts": [
            "write_summaries = neonatal_sleep.utils.write_summaries:main",
            "write_alignments = neonatal_sleep.utils.write_alignment:main"
        ]
    }
)
