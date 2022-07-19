# require "malloc_pthread_shim"
require "gobject/gtk/autorun"
# require "gobject/gtk"

module Run
    class Gui
        def run
            # application = Gtk::Application.new(application_id: "org.crystal.sample")
            # application.on_activate do
            #     window = Gtk::ApplicationWindow.new(application: application, title: "Hello", border_width: 20)
            #     window.connect "destroy", &->application.quit
            #     window.add Gtk::Label.new("Hello World!")
            #     window.show_all
            # end
            # application.run

            # dialog = Gtk::MessageDialog.new text: "Hello world!", message_type: :info, buttons: :ok, secondary_text: "This is an example dialog."
            # dialog.on_response do
            #     Gtk.main_quit
            #     end
            # dialog.show

            window = Gtk::Window.new(title: "Hello World!", border_width: 10)
            # window.connect "destroy", &->Gtk.main_quit
            button = Gtk::Button.new label: "Hello World!"
            button.on_clicked do |button|
                p! button
                puts "Hello World!"
            end
            button.connect "clicked", &->window.destroy
            window.add button
            window.show_all
        end
    end
end