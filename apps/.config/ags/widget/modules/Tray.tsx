import { Gtk } from "ags/gtk4"
import AstalTray from "gi://AstalTray"
import { createBinding, For } from "ags"

export default function Tray() {
  const tray = AstalTray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box class="tray-module" valign={Gtk.Align.CENTER} spacing={4} visible={items(i => i.length > 0)}>
      <For each={items} id={item => item.item_id}>
        {item => {
          const btn = new Gtk.Button()
          btn.add_css_class("tray-item")
          btn.valign = Gtk.Align.CENTER
          btn.child = new Gtk.Image({ gicon: item.gicon, pixel_size: 16 })
          btn.connect("clicked", () => item.activate(0, 0))

          if (item.menu_model) {
            const pop = new Gtk.PopoverMenu({ menu_model: item.menu_model })
            if (item.action_group)
              pop.insert_action_group("dbusmenu", item.action_group)
            pop.set_parent(btn)

            const gesture = new Gtk.GestureClick()
            gesture.button = 3
            gesture.connect("pressed", () => pop.popup())
            btn.add_controller(gesture)
          }

          return btn
        }}
      </For>
    </box>
  )
}
