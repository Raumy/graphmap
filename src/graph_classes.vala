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

using Cairo;
using Json;

public class Edge {
    Vertex origin;
    Vertex destination;
    Json.Object objet;

    public Vertex get_origin() {return origin;}
    public Vertex get_destination() {return destination;}

    public Edge(Vertex org, Vertex dest) {
        origin = org;
        destination = dest;
        objet = null;
    }

    public Edge.Node(Vertex org, Vertex dest, Json.Object n) {
        origin = org;
        destination = dest;
        objet = n;
    }


}

public class Vertex {
    public string get_name() {return name;} 
    public GLib.Array<Edge> get_edges() {return edges;}

    protected string vertex_name;

    protected string name;
    protected GLib.Array<Edge> edges;
    public Json.Object objet = null;    

    public Vertex(string id) {
        name = id;
        edges = new GLib.Array<Edge>();
        vertex_name = "vertex";
    }

    public Vertex.Node(string id,  Json.Object n) {
        name = id;
        edges = new GLib.Array<Edge>();
        vertex_name = "vertex";
        objet = n;
    }

    public string get_vertex_name() {
        return vertex_name;
    }

    public void set_vertex_name(string s) {
        vertex_name = s;
    }

    public void addEdge(Vertex v, Json.Object n = null)  {
        for (int i = 0; i < edges.length; i++) {
            Edge e = edges.index(i);
            if (e.get_destination() == v) return;
        }
        Edge newEdge = null;

        if (n != null)
            newEdge = new Edge(this, v);
        else
            newEdge = new Edge.Node(this, v, n);

        edges.append_val(newEdge);
    }

    public void printEdges()   {
        stdout.printf ("%s\n", name);

        for (int i = 0; i < edges.length; i++) {
        Edge e = edges.index(i);
        stdout.printf ("%s\n", e.get_destination().get_name());
        }
    }
}


public class Graph {
    public GLib.Array<Vertex> vertices;

    string vertices_name;

    public Graph() {
        vertices = new GLib.Array<Vertex>();
        vertices_name = "vertex";
    }

    public string get_vertices_name() {
        return vertices_name;
    }

    public void set_vertices_name(string s) {
        vertices_name = s;
    }

    public void insert(Vertex v) {
        vertices.append_val(v);
    }

    public void printGraph(bool onlyEdged = false) {
    Vertex vertex = null;
        for (int i = 0; i < vertices.length; i++) {
            vertex = vertices.index(i);

            if ((onlyEdged == false) || ((onlyEdged == true) && (vertex.get_edges().length > 0))) {
                vertex.printEdges();
                stdout.printf ("\n");
            }
        }
        stdout.printf ("\n");
    }

    public Vertex search(string id) {
        Vertex vertex = null;
        for (int i = 0; i < vertices.length; i++) {
            vertex = vertices.index(i);
            if (vertex.get_name() == id) return vertex;
        }
        return null;
    }

}

public class MapVertex {
    public double x;
    public double y;
    public double radius;
    public Vertex vertex;

    public double left { get { return x - radius; } }
    public double top { get { return y - radius; } }
    public double width { get { return radius * 2; } }
    public double height { get { return radius * 2; } }

    public double rel_click_x;
    public double rel_click_y;

    public Vertex get_vertex() {  return vertex; } 

    public MapVertex(Vertex u) {
        vertex = u;
        x = 25;
        y = 25;
        radius = 25;
    }

    public void put(double x, double y) {
        this.x = x;
        this.y = y;
    }

    public bool is_clicked(double cx, double cy) {
        if ((x - radius < cx) && (cx < x + radius ) &&
            (y - radius < cy) && (cy < y + radius )) return true;

        return false;

    }

    public virtual  void set_vertex_shape(Context ctx) {
        ctx.set_line_width (4);
        ctx.set_source_rgb (0, 0, 0);       
    }

    public virtual void draw(Context ctx) {
        Cairo.TextExtents extents;

        ctx.set_source_rgb (0, 1, 0);
        ctx.save();

        set_vertex_shape(ctx);

        ctx.arc (x, y, radius, 0, 2.0 * 3.14);
        ctx.fill();
        ctx.restore();
 
        ctx.set_source_rgb (0, 0, 0);
        ctx.select_font_face ("Arial", Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
        ctx.set_font_size (12);   

        ctx.text_extents (vertex.get_name(), out extents);
        ctx.move_to(x - (int) (extents.width /2), y + radius + 15);
        ctx.show_text (vertex.get_name());
    }

}


public class GraphMap {
    public GLib.Array<MapVertex> map_vertices = null;
    public string map_name;

    public uint length { get { return map_vertices.length; } }
    public virtual MapVertex index(int i) { return map_vertices.index(i); }

    public GraphMap(string nm_carte) {
        map_vertices = new GLib.Array<MapVertex>();
        map_name = nm_carte;
    }

    public virtual MapVertex insert(Vertex u) {
        MapVertex mu = new MapVertex(u);
        map_vertices.append_val(mu);
        return mu;
    }

    public MapVertex search(Vertex u) {
        MapVertex map_vertex = null;
        for (int i = 0; i < map_vertices.length; i++) {
            map_vertex = map_vertices.index(i);
            if (map_vertex.get_vertex().get_name() == u.get_name()) 
                return map_vertex;
        }
        return null;
    }

    public bool remove(MapVertex mu) {
        MapVertex map_vertex = null;
        for (int i = 0; i < map_vertices.length; i++) {
            map_vertex = map_vertices.index(i);
            if (map_vertex == mu) {
                map_vertices.remove_index (i) ;
                return true;
            }
        }
        return false;
    }

    public void save(string filename) {
        var parser = new Json.Parser ();
        parser.load_from_file(filename);

        var root_object = parser.get_root ().get_object ();

        Json.Builder builder = new Json.Builder ();
        builder.begin_object ();

        var liste_cartes = root_object.get_members ();

        foreach (string s in liste_cartes) {
            if (s != map_name) {
                Json.Node zinode = root_object.get_member(s);
                builder.set_member_name(s);
                builder.add_value(zinode);
            }
        }

        builder.set_member_name (map_name);
        builder.begin_array ();

        for (int i = 0; i < map_vertices.length; i++) {
            var map_vertex = map_vertices.index(i);
            builder.begin_object();
            builder.set_member_name(map_vertex.get_vertex().get_vertex_name());
            builder.add_string_value(map_vertex.get_vertex().get_name());

            builder.set_member_name("x");
            builder.add_int_value((int) map_vertex.x);

            builder.set_member_name("y");
            builder.add_int_value((int) map_vertex.y);
            builder.end_object();
        }
        builder.end_array ();

        builder.end_object ();

        Json.Generator generator = new Json.Generator ();
        generator.set_pretty(true);
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        var file_out = File.new_for_path (filename);
        if (file_out.query_exists ()) {
            file_out.delete ();
        }

        var dos = new DataOutputStream (file_out.create (FileCreateFlags.REPLACE_DESTINATION));

        generator.to_stream (dos);

    }

    public virtual void load(string filename, Graph g, string nm_carte) {
        MapVertex mu = null;

        try {

            var parser = new Json.Parser ();
            parser.load_from_file(filename);

            var root_object = parser.get_root ().get_object ();
            var results = root_object.get_array_member (nm_carte);

            foreach (var geonode in results.get_elements ()) {
                var geoname = geonode.get_object ();

                Vertex u = (Vertex) g.search(geoname.get_string_member (g.get_vertices_name()).up());

                if (u != null) {
                    mu = new MapVertex(u);
                    mu.put(
                        (double) geoname.get_int_member ("x"),
                        (double) geoname.get_int_member ("y"));
                    map_vertices.append_val(mu);

                }
            }
        } catch (Error e) {
                 error ("%s", e.message);
        }

    }
}



Graph load_definition_file(string name) {
    var g = new Graph();

    var parser = new Json.Parser ();
    parser.load_from_file("definitions_%s.json".printf(name));

    var root_object = parser.get_root ().get_object ();
    var results = root_object.get_array_member ("vertices");

    foreach (var geonode in results.get_elements ()) {
        var geoname = geonode.get_object ();

        Vertex v = new Vertex (
            geoname.get_string_member ("name").up()
        );
        g.insert(v);
    }

    
    results = root_object.get_array_member ("edges");

    foreach (var geonode in results.get_elements ()) {
            var geoname = geonode.get_object ();

            string v_src = geoname.get_string_member ("src");
            string v_dst = geoname.get_string_member ("dst");

            Vertex from = g.search(v_src.up());

            if (from == null) {
                stdout.printf ("A: %s\n", v_src);
                continue;
            }

            Vertex to = g.search(v_dst.up());

            if (to == null) {
                stdout.printf ("B: %s\n", v_dst);
                continue;
            }

            from.addEdge(to, geoname);
    }

    return g;
}    

bool is_same_peers_links(Edge l1, Edge l2) {
    return
        (
            (
                (l1.get_origin().get_name() == l2.get_origin().get_name()) 
                && 
                (l1.get_destination().get_name() == l2.get_destination().get_name())
            ) 
            ||
           (
                (l1.get_origin().get_name() == l2.get_destination().get_name()) 
                && 
                (l1.get_destination().get_name() == l2.get_origin().get_name())
            )
        );    
}

int edge_is_already_drawn(Edge l,  GLib.Array<Edge> a) {
    int count = 0;
    Edge liaison = null;
    for (int i = 0; i < a.length; i++) {
        liaison = a.index(i);
        if (is_same_peers_links(l, liaison)) {
            count++;
        }
    }
    return count;
}

