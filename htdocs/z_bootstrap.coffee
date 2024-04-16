window.bootstrap = ()->
  ReactDOM.render(
    React.createElement(App),
    document.getElementById("mount_point")
  )
window.bootstrap()