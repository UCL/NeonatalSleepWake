from pathlib import Path
import tkinter as tk
from tkinter import ttk
from tkinter.filedialog import askdirectory


class AlignmentInterface(tk.Tk):
    def __init__(self):
        super().__init__()
        self.data_directory = None
        self.state = "REM"
        self.first_observed = False
        self.align_btn = None
        self.create_gui()

    def create_gui(self):
        choose_dir_btn = ttk.Button(master=self, text="Choose data folder")
        choose_dir_btn.configure(command=self.choose_directory)
        choose_dir_btn.pack()

        align_btn = ttk.Button(master=self, text="Get alignments",
                               state="disabled")
        align_btn.configure(command=self.do_alignment)
        align_btn.pack()
        self.align_btn = align_btn

        # TODO Radio buttons and checkbox for alignment options
        # TODO File dialog to choose location of output

    def choose_directory(self):
        self.data_directory = askdirectory(initialdir=Path.home())
        if self.data_directory:
            self.align_btn["state"] = "normal"
        print(self.data_directory)

    def do_alignment(self):
        # TODO Do the alignments...
        print(f"Will do alignment on {self.data_directory} by {self.state} "
              f"{'(occurrence)' if self.first_observed else '(jump)'}")


if __name__ == "__main__":
    AlignmentInterface().mainloop()
