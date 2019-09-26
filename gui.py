from pathlib import Path
import tkinter as tk
from tkinter import ttk
from tkinter.filedialog import askdirectory

from .write_alignment import create_alignments


class AlignmentInterface(tk.Tk):
    def __init__(self):
        super().__init__()
        self.data_directory = None
        self.state = tk.StringVar(value="REM")
        self.first_observed = tk.BooleanVar(value=False)
        self.align_btn = None
        self.create_gui()

    def create_gui(self):
        # Main buttons
        choose_dir_btn = ttk.Button(master=self, text="Choose data folder")
        choose_dir_btn.configure(command=self.choose_directory)
        choose_dir_btn.pack()

        align_btn = ttk.Button(master=self, text="Get alignments",
                               state="disabled")
        align_btn.configure(command=self.do_alignment)
        align_btn.pack()
        self.align_btn = align_btn

        # Alignment options
        for state in ["REM", "nREM", "Awake", "Trans"]:
            btn = ttk.Radiobutton(master=self, text=state,
                                  variable=self.state, value=state)
            btn.pack()
        check = ttk.Checkbutton(master=self, text="Align at first occurrence",
                                variable=self.first_observed)
        check.pack()

        # TODO File dialog to choose location of output

    def choose_directory(self):
        self.data_directory = askdirectory(initialdir=Path.home())
        if self.data_directory:
            self.align_btn["state"] = "normal"
        print(self.data_directory)

    def do_alignment(self):
        print(f"Will do alignment on {self.data_directory} by {self.state.get()} "
              f"{'(occurrence)' if self.first_observed.get() else '(jump)'}")
        # Save at current directory for now
        create_alignments(self.data_directory, self.state.get(),
                          self.first_observed.get(), Path.cwd())


if __name__ == "__main__":
    AlignmentInterface().mainloop()
