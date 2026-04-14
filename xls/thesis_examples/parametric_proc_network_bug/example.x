// this is grabbed from https://github.com/google/xls/issues/2039

proc Foo<N: u32> {
  init {
    token()
  }
  config() {
  }
  next(state: token) {
    state
  }
}

proc example {
  init {

  }
  config() {
    spawn Foo<u32:32>(); 
  }

  next(state: ()) {

  }
}