
PROFILE = False

''' function decorator to quickly switch between profiling and no profiling '''
def profile_code(cond):
    def resdec(f):
        if not cond:
            return f
        # profile(f) will only work, if our program is invoked by 
        # 'kernprof.py -l my_prog.py', otherwise we'll get a nasty error.
        # catch the potential error and return the function itself.
        try:
            return profile(f)
        except:
            pass
            return f
    return resdec



import types
''' class decorator (needs python > 2.6) to quickly switch between profiling and no profiling '''
def do_profile_all_methods(cond):
    if not cond:
        return lambda c: c # Do nothing with the class; the 'null' decorator
    def profile_all_methods(klass):
        for name, attr in klass.__dict__.items():
            if isinstance(attr, types.UnboundMethodType):
                klass[name] = profile(attr)
        return klass
    return profile_all_methods


