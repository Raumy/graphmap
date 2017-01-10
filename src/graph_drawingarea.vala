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

 using Gtk;
using Cairo;

public class cArea : DrawingArea {
    GraphMap gm = null;
    MapVertex selected = null;
    MapVertex _save_selected = null;
    Vertex drag_vertex = null;

    public bool is_drag_drop = false;

    public cArea(GraphMap graph_map) {
        set_size_request (1366, 725);

        gm = graph_map;

        this.draw.connect(on_draw);

        add_events(Gdk.EventMask.POINTER_MOTION_MASK);
        add_events(Gdk.EventMask.BUTTON_PRESS_MASK);
        add_events(Gdk.EventMask.BUTTON_RELEASE_MASK);

        motion_notify_event.connect(on_drawingarea_mouse_move);
        button_press_event.connect(on_drawingarea_button_press_event);
        button_release_event.connect(on_drawingarea_button_release_event);

    }

    public GraphMap get_graphmap() {
        return gm;
    }

    public void save_graphmap() {
        gm.save("graph_%s.json".printf(UP));        
    }

    public void set_map(int index) {
        selected_map = index;
        gm = new GraphMap(liste_cartes.index(selected_map));
        gm.load("graph_%s.json".printf (UP), referentiel_graph, liste_cartes.index(selected_map));        
        redraw();
    }

    public void save_selected() {
        _save_selected = selected;
        selected = null;
    }

    public void restore_selected() {
        selected = _save_selected;
    }

    public void reset_selected() {
        selected = null;
    }
    public bool remove_selected_vertex() {
        if (gm.remove(selected)) {
            reset_selected();
            redraw();
            return true;
        }
        return false;
    }

    public bool on_drawingarea_mouse_move(Gdk.EventMotion event) {
        if (is_drag_drop) {
            selected.put(event.x - selected.rel_click_x, event.y - selected.rel_click_y);
            redraw();
        }

        return true;
    }

    public bool on_drawingarea_button_press_event(Widget w, Gdk.EventButton event) {
        for (int i = 0; i < gm.length; i++) {
            var mu = (MapVertex) gm.index(i);
            if (mu.is_clicked(event.x, event.y)) {
                selected = mu;
                is_drag_drop = true;
                selected.rel_click_x = event.x - selected.x;
                selected.rel_click_y = event.y -  selected.y;
                redraw();
                return true;
            }
        }

        if (selected != null) {
            selected = null;
            redraw();
        }

        return true;
    }

    public bool on_drawingarea_button_release_event(Widget w, Gdk.EventButton event) {
        if (is_drag_drop) save_graphmap();
        is_drag_drop = false;
        return true;
    }

    public bool on_draw(Widget da, Context context) {
        context.save();
        GLib.List<MapVertex> vertices_to_draw = new GLib.List<MapVertex>();

        MapVertex mu_from = null;
        MapVertex mu_to = null;

        context.set_source_rgb (0, 0, 0);
        Vertex vertex = null;

        // optimisation possible

        GLib.Array<Edge> already_drawn = new GLib.Array<Edge>();


        for (int i = 0; i < gm.length; i++) {
            mu_from = gm.index(i);
            Vertex v = mu_from.get_vertex();

            if (vertices_to_draw.index(mu_from) == -1) {
                vertices_to_draw.append(mu_from);
            }


            for (int j = 0; j < v.get_edges().length; j++) {
                Edge e = (Edge) v.get_edges().index(j);
                Vertex to_vertex = e.get_destination();

               // if (edge_is_already_drawn(e, already_drawn)) continue;
               // if (edge_is_already_drawn(e, already_drawn) != 0) continue;
               // int rel_y = 0;
                
               int n = edge_is_already_drawn(e, already_drawn);
               // stdout.printf ("%s <-> %s : %d\n",e.get_origin().get_name(), e.get_destination().get_name(), n);
               int rel_y = n * 5;
                
                mu_to = (MapVertex) gm.search(to_vertex);

                if ((mu_to != null) && (vertices_to_draw.index(mu_to) == -1))
                    vertices_to_draw.append(mu_to);

                if ((mu_from != null) && (mu_to != null)) {
                    context.set_source_rgb (0, 0, 1);
                    context.move_to(mu_from.x + rel_y, mu_from.y + rel_y);
                    context.line_to(mu_to.x + rel_y, mu_to.y + rel_y);
                    context.stroke();                    
                    context.restore();

                    already_drawn.append_val(e);
                }      
            }
        }

        vertices_to_draw.foreach ((entry) => {
            entry.draw(context);
        });

       if (selected != null) {
            context.rectangle (selected.left - 2, selected.top - 2, selected.width + 4, selected.height + 4);
            context.stroke();
        }

        return true;
    }

    public void redraw(bool with_selected = true) {
        MapVertex tmp = null;

        if (! with_selected) {
            tmp = selected;
            selected = null;
        }

        queue_draw_area (0, 0,
            get_allocated_width(), get_allocated_height());    

        if (! with_selected) {
            selected = tmp;
        }
    }

    public MapVertex add_vertex(Vertex v) {
    	if (gm == null) stdout.printf("gm nok\n");
    	if (gm.map_vertices == null)   stdout.printf("gm  nok\n");

        MapVertex mu = new MapVertex(v);
        gm.map_vertices.append_val(mu);    	

    	return mu;
    }
}
