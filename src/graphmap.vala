/*
 *
 * Copyright 2013-2016 Cyriac REMY <raum@no-log.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */

 // valac --pkg gtk+-3.0 --pkg json-glib-1.0 graphmap.vala graph_classes.vala graph_drawingarea.vala

using Json;
using Gtk;
using Cairo;

string DEF_NAME;
int selected_map = 0;

public class cSignalsHandler {
	bool drag_en_cours = false;
	//GraphMap gm = null;

	public cSignalsHandler() {

	}


    [CCode (cname="G_MODULE_EXPORT key_press_event")]
    public bool key_press_event(Gdk.EventKey event) {
         if (Gdk.keyval_name(event.keyval).up() == "DELETE") {
            drawing_area.remove_selected_vertex();
            fill_tv_vertices();   
            return true;         
         }
         return false;
    }

    [CCode (cname="G_MODULE_EXPORT event_save_bitmap")]
    public bool event_save_bitmap() {
        int width = drawing_area.get_allocated_width();
        int height = drawing_area.get_allocated_height();

        Cairo.ImageSurface surface;
        Cairo.Context cr;

        surface = new Cairo.ImageSurface (Cairo.Format.RGB24, width, height);

        cr = new Cairo.Context (surface);
        cr.set_source_rgb (1, 1, 1);
        cr.rectangle(0, 0, width, height);
        cr.fill();

        drawing_area.save_selected();
        drawing_area.draw(cr);
        drawing_area.restore_selected();


        Gdk.Pixbuf result= Gdk.pixbuf_get_from_surface(surface, 0, 0, width, height);

        result.save("carte_%s_%s.png".printf (DEF_NAME, drawing_area.get_graphmap().map_name),  "png");

        return false;

    }


    [CCode (cname="G_MODULE_EXPORT event_change_map")]
    public void event_change_map() {
        var cbb = ui_builder.get_object("combobox1") as Gtk.ComboBox;
        var index = cbb.get_active();
       
        drawing_area.reset_selected();
        drawing_area.set_map(index);
        fill_tv_vertices();
    }


    [CCode (cname="G_MODULE_EXPORT vertices_press_event")]
    public bool vertices_press_event() {
    	drag_en_cours = true;

        return false;

    }

    [CCode (cname="G_MODULE_EXPORT vertices_release_event")]
    public bool vertices_release_event(Widget w, Gdk.EventButton event) {
    	if (drag_en_cours) {
            var ls_text = ui_builder.get_object("ls_vertices") as Gtk.ListStore;
            var tv = ui_builder.get_object("treeview2") as Gtk.TreeView;
            var selection = tv.get_selection();
            int x; int y;

            tv.get_pointer(out x, out y);

            if (x < -5) {
    	        TreeIter iter;
    	        TreeModel model;
    	        Value val;

    	    	 bool valid = selection.get_selected (out model, out iter);

    	    	 if (! valid) return false;

    	        ls_text.get_value (iter, 1, out val);

    	        Vertex v = referentiel_graph.search((string) val);

    			var mu = drawing_area.add_vertex(v);

                drawing_area.get_pointer (out x, out  y);
    			mu.put (x, y);

                drawing_area.reset_selected();
                drawing_area.redraw(false);
                fill_tv_vertices();
                drawing_area.save_graphmap();
            }

    	}
    	drag_en_cours = false;	
    	return false;
    }

}


Graph referentiel_graph = null;
cArea drawing_area = null;

Gtk.Builder ui_builder = null;
GLib.Array<string> liste_cartes = null;

void init_builder() {
    ui_builder = new Gtk.Builder();
    try {
        ui_builder.add_from_file("graphmap.ui");
    } catch (Error err) {
        stdout.printf("Error : %s\n", err.message);
    }
}

void load_liste_cartes() {
    liste_cartes = new GLib.Array<string>();

    var parser = new Json.Parser ();
    parser.load_from_file("graph_%s.json".printf(DEF_NAME));

    var root_object = parser.get_root ().get_object ();
    var tmp  = root_object.get_members ();
    foreach (var s in tmp) {
        liste_cartes.append_val(s);
    }
}

void fill_tv_vertices() {
    var gm = drawing_area.get_graphmap();

    Gtk.ListStore ls_vertices = ui_builder.get_object("ls_vertices") as Gtk.ListStore;
    Gtk.TreeIter iter;

    ls_vertices.clear();
    ls_vertices.set_sort_column_id (1, SortType.ASCENDING);    

    for (int i = 0; i < referentiel_graph.vertices.length; i++) {
        Vertex v = referentiel_graph.vertices.index(i);
        if (gm.search(v) == null) {
            ls_vertices.append (out iter);        
            ls_vertices.set (iter,  1, v.get_name());
        }
    }
}

int main(string[] args) {
    bool stat_arg = false;
    bool convert_to_csv = false;


        DEF_NAME = args[1];


stdout.printf ("loading definition file\n");

     referentiel_graph = load_definition_file(DEF_NAME);

stdout.printf ("loading maps list\n");
    load_liste_cartes();

    var gm = new GraphMap(liste_cartes.index(selected_map));
    gm.load("graph_%s.json".printf (DEF_NAME), referentiel_graph, liste_cartes.index(selected_map));

stdout.printf ("Initializing GTK\n");

    Gtk.init (ref args);

	init_builder();

	drawing_area = new cArea (gm);

    cSignalsHandler o = new cSignalsHandler();

	ui_builder.connect_signals(o);
	var window = ui_builder.get_object("main_window") as Window;
	window.destroy.connect (Gtk.main_quit);
	window.set_default_size (800, 300);

	Gtk.Viewport tmp = ui_builder.get_object("viewport1") as Gtk.Viewport;
	tmp.add(drawing_area);

    fill_tv_vertices();

    Gtk.TreeIter iter;
    var liststore2 = ui_builder.get_object("ls_cartes") as Gtk.ListStore;

    for (int i = 0; i < liste_cartes.length; i++) {
        string nm_carte = liste_cartes.index(i);

        liststore2.append (out iter);       
        liststore2.set (iter, 0, nm_carte);
    }

    var cbb = ui_builder.get_object("combobox1") as Gtk.ComboBox;
    cbb.set_active(0);

   	window.show_all ();
  	Gtk.main ();

    return 0;
}


