import Tkinter as tk


def return_tk_root():
    # setup & hide Tkinter window
    root = tk.Tk()
    root.withdraw()
    return root


from tkSimpleDialog import askstring
class get_one_input(object):

    result = False
    root = False

    def __init__(self, *args, **kwargs):
        pass


    def run(self, window_title = 'window', label_strg = 'pleave provide input'):
        self.root = return_tk_root()
        self.result = askstring(window_title, label_strg)
        self.root.destroy()


class get_two_inputs(object):

    dialog = False
    root = False

    def __init__(self, *args, **kwargs):
        pass


    def run(self, window_title = 'window', label1 = 'label1', label2 = 'label2', default1 = None, default2 = None):
        self.root = return_tk_root()
        self.dialog = two_inputs_dialog(self.root, window_title, label1, label2, default1, default2)
        self.root.destroy()


import tkSimpleDialog
class two_inputs_dialog(tkSimpleDialog.Dialog):

    result = False
    default1 = False
    default2 = False

    def __init__(self, parent, title = 'window', label1 = 'label1', label2 = 'label2', default1 = None, default2 = None):
        self.label1 = label1
        self.label2 = label2
        if default1:
            self.default1 = default1
        if default2:
            self.default2 = default2
        tkSimpleDialog.Dialog.__init__(self, parent, title)


    def body(self, master):

        tk.Label(master, text = self.label1).grid(row=0)
        tk.Label(master, text = self.label2).grid(row=1)

        self.e1 = tk.Entry(master)
        self.e2 = tk.Entry(master)

        # insert default values if available - allow '0', therefore we check for 
        # 'is not None' here.
        if self.default1 is not None:
            self.e1.insert(0, self.default1)

        if self.default2 is not None:
            self.e2.insert(0, self.default2)

        self.e1.grid(row=0, column=1)
        self.e2.grid(row=1, column=1)

         # give initial focus on e1
        return self.e1


    def apply(self):
        first = self.e1.get()
        second = self.e2.get()
        # save the resulting inputs.
        self.result = first, second


''' top level window class '''
class mainWindowClass(object):
    def __init__(self, master):
        self.top = tk.Toplevel(master)
        self.top.protocol('WM_DELETE_WINDOW', self.quit)   #close button
    def quit(self):
        self.top.destroy()


''' simple text box dialog '''
class text_info(object):

    dialog = False
    root = False

    def __init__(self, *args, **kwargs):
        pass


    def run(self, window_title = 'window', textfield = 'some text', label = None):
        self.root = return_tk_root()
        self.dialog = TextInfo(self.root, window_title, textfield, label)
        # window won't show up if I don't uncomment one of the following lines
        #self.root.wait_window(self.dialog.top)
        #self.root.mainloop()
        # don't call root.destroy() here because the window should stay open
        # until closed by user.


class TextInfo(mainWindowClass):

    def __init__(self, parent, window_title = 'window', textfield = 'a text field', label = None):
        super(TextInfo, self).__init__(parent)

        self.parent = parent
        self.window_title = window_title
        self.textfield = textfield

        # set window title
        if window_title:
            self.top.title(window_title)

        # add label if given
        if label:
            tk.Label(self.top, text=window_title).grid(row=0)

        # create the text field
        self.textField = tk.Text(self.top, width=80, height=20, wrap=tk.NONE)
        if textfield:
            self.textField.insert(1.0, textfield)
        self.textField.grid(row=1)

        # create the ok button
        b = tk.Button(self.top, text="OK", command=self.ok)
        b.grid(row=2)

    def ok(self):
        self.top.destroy()


