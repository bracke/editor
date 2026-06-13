with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Contextual_Help;
with Editor.Font_Config;
with Editor.Panels;

package body Editor.File_Tree_View is

   use type Editor.File_Tree.File_Tree_Node_Kind;
   use type Editor.File_Tree.File_Tree_Node_Id;

   Current : File_Tree_View_Config := (others => <>);
   Current_View_State : File_Tree_View_State :=
     (Width_In_Columns   => Current.Default_Width_In_Columns,
      Selected_Row_Index => 0,
      Top_Row            => 1);

   function Panel_Config_From_Current return Editor.Panels.Panel_Config is
   begin
      return
        (Enabled              => Current.Enabled,
         Side                 => Editor.Panels.Left_Side,
         Default_Size         => Current.Default_Width_In_Columns,
         Minimum_Size         => Current.Minimum_Width_In_Columns,
         Maximum_Size         => Current.Maximum_Width_In_Columns,
         Splitter_Size_Pixels => Current.Splitter_Width_In_Pixels,
         Size_Unit            => Editor.Panels.Columns,
         Resizable            => True);
   end Panel_Config_From_Current;

   procedure Synchronize_Panel_State is
      Panels : Editor.Panels.Panel_Set := Editor.Panels.Current;
   begin
      Editor.Panels.Set_Config
        (Panels, Editor.Panels.File_Tree_Panel, Panel_Config_From_Current);
      Editor.Panels.Set_Current_Size
        (Panels, Editor.Panels.File_Tree_Panel,
         Effective_Width_In_Columns (Current, Current_View_State));
      Editor.Panels.Set_Visible
        (Panels, Editor.Panels.File_Tree_Panel, Current.Enabled);
      Editor.Panels.Set_Current (Panels);
   end Synchronize_Panel_State;



   procedure Clear_View
     (View : in out File_Tree_View_State)
   is
   begin
      View.Selected_Row_Index := 0;
      View.Top_Row := 1;
   end Clear_View;

   function Selected_Row_Index
     (View : File_Tree_View_State) return Natural
   is
   begin
      return View.Selected_Row_Index;
   end Selected_Row_Index;

   procedure Set_Selected_Row_Index
     (View  : in out File_Tree_View_State;
      Index : Natural)
   is
   begin
      View.Selected_Row_Index := Index;
   end Set_Selected_Row_Index;

   function Top_Row
     (View : File_Tree_View_State) return Natural
   is
   begin
      return View.Top_Row;
   end Top_Row;

   procedure Set_Top_Row
     (View : in out File_Tree_View_State;
      Row  : Natural)
   is
   begin
      if Row = 0 then
         View.Top_Row := 1;
      else
         View.Top_Row := Row;
      end if;
   end Set_Top_Row;

   function Visible_Count
     (Tree : Editor.File_Tree.File_Tree_State) return Natural
   is
   begin
      return Editor.File_Tree.Visible_Row_Count (Tree);
   end Visible_Count;

   procedure Ensure_Valid_Selection
     (View : in out File_Tree_View_State;
      Tree : Editor.File_Tree.File_Tree_State)
   is
      Count : constant Natural := Visible_Count (Tree);
   begin
      if Count = 0 then
         View.Selected_Row_Index := 0;
         View.Top_Row := 1;
      elsif View.Selected_Row_Index = 0 then
         View.Selected_Row_Index := 1;
      elsif View.Selected_Row_Index > Count then
         View.Selected_Row_Index := Count;
      end if;

      if View.Top_Row = 0 then
         View.Top_Row := 1;
      elsif Count > 0 and then View.Top_Row > Count then
         View.Top_Row := Count;
      end if;
   end Ensure_Valid_Selection;

   procedure Move_Selection
     (View      : in out File_Tree_View_State;
      Tree      : Editor.File_Tree.File_Tree_State;
      Direction : File_Tree_Row_Direction;
      Wrap      : Boolean := False)
   is
      Count : constant Natural := Visible_Count (Tree);
   begin
      if Count = 0 then
         View.Selected_Row_Index := 0;
         View.Top_Row := 1;
         return;
      end if;

      Ensure_Valid_Selection (View, Tree);
      case Direction is
         when Previous_Row =>
            if View.Selected_Row_Index > 1 then
               View.Selected_Row_Index := View.Selected_Row_Index - 1;
            elsif Wrap then
               View.Selected_Row_Index := Count;
            end if;
         when Next_Row =>
            if View.Selected_Row_Index < Count then
               View.Selected_Row_Index := View.Selected_Row_Index + 1;
            elsif Wrap then
               View.Selected_Row_Index := 1;
            end if;
      end case;
   end Move_Selection;

   procedure Move_Selection_By
     (View  : in out File_Tree_View_State;
      Tree  : Editor.File_Tree.File_Tree_State;
      Step_Delta : Integer)
   is
      Count : constant Natural := Visible_Count (Tree);
      Next  : Integer;
   begin
      if Count = 0 then
         View.Selected_Row_Index := 0;
         View.Top_Row := 1;
         return;
      end if;

      Ensure_Valid_Selection (View, Tree);
      Next := Integer (View.Selected_Row_Index) + Step_Delta;

      if Next < 1 then
         View.Selected_Row_Index := 1;
      elsif Next > Integer (Count) then
         View.Selected_Row_Index := Count;
      else
         View.Selected_Row_Index := Natural (Next);
      end if;
   end Move_Selection_By;

   function Node_For_Row
     (Tree      : Editor.File_Tree.File_Tree_State;
      Row_Index : Natural;
      Found     : out Boolean)
      return Editor.File_Tree.File_Tree_Node_Id
   is
   begin
      if Row_Index = 0
        or else Row_Index > Editor.File_Tree.Visible_Row_Count (Tree)
      then
         Found := False;
         return Editor.File_Tree.No_File_Tree_Node;
      end if;

      return Editor.File_Tree.Node_At_Visible_Row
        (Tree, Positive (Row_Index), Found);
   end Node_For_Row;

   function Row_For_Node
     (Tree    : Editor.File_Tree.File_Tree_State;
      Node_Id : Editor.File_Tree.File_Tree_Node_Id;
      Found   : out Boolean) return Natural
   is
   begin
      if Node_Id = Editor.File_Tree.No_File_Tree_Node then
         Found := False;
         return 0;
      end if;

      for Row in 1 .. Editor.File_Tree.Visible_Row_Count (Tree) loop
         declare
            Visible : constant Editor.File_Tree.Visible_File_Tree_Row :=
              Editor.File_Tree.Visible_Row (Tree, Row);
         begin
            if Visible.Node_Id = Node_Id then
               Found := True;
               return Row;
            end if;
         end;
      end loop;

      Found := False;
      return 0;
   end Row_For_Node;

   procedure Ensure_Selected_Row_Visible
     (View              : in out File_Tree_View_State;
      Tree              : Editor.File_Tree.File_Tree_State;
      Visible_Row_Count : Natural)
   is
      Count : constant Natural := Editor.File_Tree.Visible_Row_Count (Tree);
      Last_Top : Natural;
   begin
      Ensure_Valid_Selection (View, Tree);
      if Count = 0 or else Visible_Row_Count = 0 or else View.Selected_Row_Index = 0 then
         View.Top_Row := 1;
         return;
      end if;

      if Count <= Visible_Row_Count then
         Last_Top := 1;
      else
         Last_Top := Count - Visible_Row_Count + 1;
      end if;

      if View.Top_Row = 0 then
         View.Top_Row := 1;
      elsif View.Top_Row > Last_Top then
         View.Top_Row := Last_Top;
      end if;

      if View.Selected_Row_Index < View.Top_Row then
         View.Top_Row := View.Selected_Row_Index;
      elsif View.Selected_Row_Index >= View.Top_Row + Visible_Row_Count then
         View.Top_Row := View.Selected_Row_Index - Visible_Row_Count + 1;
      end if;
   end Ensure_Selected_Row_Visible;

   procedure Clamp_Viewport
     (View              : in out File_Tree_View_State;
      Tree              : Editor.File_Tree.File_Tree_State;
      Visible_Row_Count : Natural)
   is
      Count    : constant Natural := Editor.File_Tree.Visible_Row_Count (Tree);
      Last_Top : Natural := 1;
   begin
      if Count = 0 then
         View.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count and then Visible_Row_Count > 0 then
         Last_Top := Count - Visible_Row_Count + 1;
      end if;

      if View.Top_Row = 0 then
         View.Top_Row := 1;
      elsif View.Top_Row > Last_Top then
         View.Top_Row := Last_Top;
      end if;
   end Clamp_Viewport;

   procedure Scroll_By
     (View              : in out File_Tree_View_State;
      Tree              : Editor.File_Tree.File_Tree_State;
      Visible_Row_Count : Natural;
      Step_Delta             : Integer)
   is
      Count    : constant Natural := Editor.File_Tree.Visible_Row_Count (Tree);
      Last_Top : Natural := 1;
      Desired  : Integer := Integer (View.Top_Row) + Step_Delta;
   begin
      if Count = 0 then
         View.Top_Row := 1;
         return;
      end if;

      if Count > Visible_Row_Count and then Visible_Row_Count > 0 then
         Last_Top := Count - Visible_Row_Count + 1;
      end if;

      if Desired < 1 then
         Desired := 1;
      elsif Desired > Integer (Last_Top) then
         Desired := Integer (Last_Top);
      end if;

      View.Top_Row := Natural (Desired);
   end Scroll_By;

   procedure Select_First_Visible_Row
     (View : in out File_Tree_View_State;
      Tree : Editor.File_Tree.File_Tree_State)
   is
   begin
      if Visible_Count (Tree) = 0 then
         View.Selected_Row_Index := 0;
      else
         View.Selected_Row_Index := 1;
      end if;
   end Select_First_Visible_Row;

   procedure Select_Last_Visible_Row
     (View : in out File_Tree_View_State;
      Tree : Editor.File_Tree.File_Tree_State)
   is
      Count : constant Natural := Visible_Count (Tree);
   begin
      View.Selected_Row_Index := Count;
   end Select_Last_Visible_Row;

   function Current_Config return File_Tree_View_Config is
   begin
      return Current;
   end Current_Config;

   function Current_State return File_Tree_View_State is
   begin
      return Current_View_State;
   end Current_State;

   procedure Set_Current_Config
     (Config : File_Tree_View_Config)
   is
   begin
      Current := Config;
      Set_Width_In_Columns
        (Current_View_State, Current, Current_View_State.Width_In_Columns);
      Synchronize_Panel_State;
   end Set_Current_Config;

   procedure Set_Current_State
     (State : File_Tree_View_State)
   is
   begin
      Current_View_State := State;
      Set_Width_In_Columns
        (Current_View_State, Current, Current_View_State.Width_In_Columns);
      Synchronize_Panel_State;
   end Set_Current_State;

   procedure Reset is
   begin
      Current := (others => <>);
      Current_View_State :=
        (Width_In_Columns   => Current.Default_Width_In_Columns,
      Selected_Row_Index => 0,
      Top_Row            => 1);
      Synchronize_Panel_State;
   end Reset;

   function Enabled
     (Config : File_Tree_View_Config) return Boolean
   is
   begin
      return Config.Enabled;
   end Enabled;

   function Clamp_Width_In_Columns
     (Config : File_Tree_View_Config;
      Width  : Natural) return Natural
   is
   begin
      if Config.Maximum_Width_In_Columns > 0
        and then Config.Minimum_Width_In_Columns > Config.Maximum_Width_In_Columns
      then
         return Config.Maximum_Width_In_Columns;
      elsif Config.Maximum_Width_In_Columns > 0
        and then Width > Config.Maximum_Width_In_Columns
      then
         return Config.Maximum_Width_In_Columns;
      elsif Width < Config.Minimum_Width_In_Columns then
         return Config.Minimum_Width_In_Columns;
      else
         return Width;
      end if;
   end Clamp_Width_In_Columns;

   procedure Set_Width_In_Columns
     (State  : in out File_Tree_View_State;
      Config : File_Tree_View_Config;
      Width  : Natural)
   is
   begin
      State.Width_In_Columns := Clamp_Width_In_Columns (Config, Width);
   end Set_Width_In_Columns;

   function Width_In_Columns
     (Config : File_Tree_View_Config) return Natural
   is
   begin
      if not Config.Enabled then
         return 0;
      else
         return Clamp_Width_In_Columns (Config, Config.Default_Width_In_Columns);
      end if;
   end Width_In_Columns;

   function Effective_Width_In_Columns
     (Config : File_Tree_View_Config;
      State  : File_Tree_View_State) return Natural
   is
   begin
      if not Config.Enabled then
         return 0;
      else
         return Clamp_Width_In_Columns (Config, State.Width_In_Columns);
      end if;
   end Effective_Width_In_Columns;

   function Current_Width_In_Columns return Natural is
   begin
      return Effective_Width_In_Columns (Current, Current_View_State);
   end Current_Width_In_Columns;

   procedure Set_Current_Width_In_Columns
     (Width : Natural)
   is
   begin
      Set_Width_In_Columns (Current_View_State, Current, Width);
      Synchronize_Panel_State;
   end Set_Current_Width_In_Columns;

   function Width_In_Pixels
     (Config     : File_Tree_View_Config;
      Cell_Width : Natural) return Natural
   is
   begin
      return Width_In_Columns (Config) * Cell_Width;
   end Width_In_Pixels;

   function Width_In_Pixels
     (Config     : File_Tree_View_Config;
      State      : File_Tree_View_State;
      Cell_Width : Natural) return Natural
   is
   begin
      return Effective_Width_In_Columns (Config, State) * Cell_Width;
   end Width_In_Pixels;

   function Splitter_Width_In_Pixels
     (Config : File_Tree_View_Config) return Natural
   is
   begin
      if not Config.Enabled then
         return 0;
      else
         return Config.Splitter_Width_In_Pixels;
      end if;
   end Splitter_Width_In_Pixels;



   function Display_Depth
     (Config : File_Tree_View_Config;
      Node   : Editor.File_Tree.File_Tree_Node_Summary) return Natural
   is
   begin
      if (not Config.Show_Root) and then Node.Depth > 0 then
         return Node.Depth - 1;
      else
         return Node.Depth;
      end if;
   end Display_Depth;

   function Hit_Test
     (Geometry : File_Tree_Geometry;
      Config   : File_Tree_View_Config;
      Tree     : Editor.File_Tree.File_Tree_State;
      X        : Integer;
      Y        : Integer) return File_Tree_Hit_Result
   is
   begin
      return Hit_Test
        (Geometry => Geometry,
         Config   => Config,
         Tree     => Tree,
         State    => Current_View_State,
         X        => X,
         Y        => Y);
   end Hit_Test;

   function Hit_Test
     (Geometry : File_Tree_Geometry;
      Config   : File_Tree_View_Config;
      Tree     : Editor.File_Tree.File_Tree_State;
      State    : File_Tree_View_State;
      X        : Integer;
      Y        : Integer) return File_Tree_Hit_Result
   is
      Cell_W : constant Positive := Editor.Font_Config.Cell_W;
      Cell_H : constant Positive := Editor.Font_Config.Cell_H;
      Right  : constant Integer := Geometry.X + Integer (Geometry.Width);
      Bottom : constant Integer := Geometry.Y + Integer (Geometry.Height);
      Rel_Y  : Natural;
      Display_Row : Natural;
      Source_Row  : Natural;
      Emitted_Row : Natural := 0;
   begin
      if not Config.Enabled or else Geometry.Width = 0 or else Geometry.Height = 0 then
         return (Zone => Outside_File_Tree, Row => 0,
                 Node_Id => Editor.File_Tree.No_File_Tree_Node);
      end if;

      if X < Geometry.X or else X >= Right or else Y < Geometry.Y or else Y >= Bottom then
         return (Zone => Outside_File_Tree, Row => 0,
                 Node_Id => Editor.File_Tree.No_File_Tree_Node);
      end if;

      if Editor.File_Tree.Is_Empty (Tree) then
         return (Zone => File_Tree_Background_Zone, Row => 0,
                 Node_Id => Editor.File_Tree.No_File_Tree_Node);
      end if;

      Rel_Y := Natural (Y - Geometry.Y);
      Display_Row := Rel_Y / Cell_H + 1;

      if Display_Row < 1 or else Display_Row > Geometry.Height / Cell_H then
         return (Zone => File_Tree_Background_Zone, Row => 0,
                 Node_Id => Editor.File_Tree.No_File_Tree_Node);
      end if;

      Source_Row := (if State.Top_Row = 0 then 1 else State.Top_Row);
      if Source_Row > Editor.File_Tree.Visible_Row_Count (Tree) then
         return (Zone => File_Tree_Background_Zone, Row => 0,
                 Node_Id => Editor.File_Tree.No_File_Tree_Node);
      end if;

      for Row in Source_Row .. Editor.File_Tree.Visible_Row_Count (Tree) loop
         declare
            Visible : constant Editor.File_Tree.Visible_File_Tree_Row :=
              Editor.File_Tree.Visible_Row (Tree, Row);
            Node : constant Editor.File_Tree.File_Tree_Node_Summary :=
              Editor.File_Tree.Node (Tree, Visible.Node_Id);
         begin
            if (not Config.Show_Root) and then Node.Id = Editor.File_Tree.Root (Tree) then
               null;
            else
               Emitted_Row := Emitted_Row + 1;
               if Emitted_Row = Display_Row then
                  declare
                     Display_Node : constant Editor.File_Tree.File_Tree_Node_Summary := Node;
                     Depth_Cols   : constant Natural := Display_Depth (Config, Display_Node)
                       * Config.Indent_In_Columns;
                     Marker_X     : constant Integer := Geometry.X + Integer (Cell_W)
                       + Integer (Depth_Cols * Cell_W);
                     Marker_Right : constant Integer := Marker_X + Integer (Cell_W);
                     Label_X      : constant Integer := Marker_Right + Integer (Cell_W);
                  begin
                     if Node.Kind = Editor.File_Tree.Directory_Node
                       and then Config.Show_Expansion_Markers
                       and then X >= Marker_X
                       and then X < Marker_Right
                     then
                        return (Zone => File_Tree_Expansion_Zone,
                                Row => Row,
                                Node_Id => Node.Id);
                     elsif X >= Label_X then
                        return (Zone => File_Tree_Label_Zone,
                                Row => Row,
                                Node_Id => Node.Id);
                     else
                        return (Zone => File_Tree_Row_Zone,
                                Row => Row,
                                Node_Id => Node.Id);
                     end if;
                  end;
               end if;
            end if;
         end;
      end loop;

      return (Zone => File_Tree_Background_Zone, Row => 0,
              Node_Id => Editor.File_Tree.No_File_Tree_Node);
   end Hit_Test;

   function Action_For_Hit
     (Tree : Editor.File_Tree.File_Tree_State;
      Hit  : File_Tree_Hit_Result) return File_Tree_Action
   is
      Node : Editor.File_Tree.File_Tree_Node_Summary;
   begin
      if Hit.Zone = Outside_File_Tree
        or else Hit.Zone = File_Tree_Background_Zone
        or else Hit.Node_Id = Editor.File_Tree.No_File_Tree_Node
        or else not Editor.File_Tree.Contains (Tree, Hit.Node_Id)
      then
         return No_File_Tree_Action;
      end if;

      Node := Editor.File_Tree.Node (Tree, Hit.Node_Id);
      if Node.Kind = Editor.File_Tree.Directory_Node then
         return Toggle_Directory_Action;
      elsif Hit.Zone = File_Tree_Row_Zone
        or else Hit.Zone = File_Tree_Label_Zone
      then
         return Open_File_Action;
      else
         return No_File_Tree_Action;
      end if;
   end Action_For_Hit;

   function Safe_Display_Label
     (Node : Editor.File_Tree.File_Tree_Node_Summary) return String
   is
      Label : constant String := To_String (Node.Name);
   begin
      if Label'Length > 0 then
         return Label;
      elsif Node.Kind = Editor.File_Tree.Directory_Node then
         return "<unnamed folder>";
      else
         return "<unnamed file>";
      end if;
   end Safe_Display_Label;

   function Empty_State_Text return String is
   begin
      return Editor.Contextual_Help.Empty_File_Tree_Text (True);
   end Empty_State_Text;

   function Truncate_Label
     (Label       : String;
      Max_Columns : Natural) return String
   is
      Ellipsis : constant String := "...";
   begin
      if Label'Length <= Max_Columns then
         return Label;
      elsif Max_Columns = 0 then
         return "";
      elsif Max_Columns <= Ellipsis'Length then
         return Ellipsis (Ellipsis'First .. Ellipsis'First + Max_Columns - 1);
      else
         return Label (Label'First .. Label'First + Max_Columns - Ellipsis'Length - 1)
           & Ellipsis;
      end if;
   end Truncate_Label;

   function Format_Row_Text
     (Config : File_Tree_View_Config;
      Node   : Editor.File_Tree.File_Tree_Node_Summary;
      Width  : Natural) return String
   is
      Indent_Cols : constant Natural := Node.Depth * Config.Indent_In_Columns;
      Marker_Cols : constant Natural := (if Config.Show_Expansion_Markers then 2 else 0);
      Prefix_Len : constant Natural := Indent_Cols + Marker_Cols;
      Marker : Character := ' ';
      Kind_Label : constant String :=
        (if Node.Kind = Editor.File_Tree.Directory_Node then "[dir] " else "[file] ");
      Label  : constant String := Kind_Label & Safe_Display_Label (Node);
   begin
      if Width = 0 then
         return "";
      end if;

      if Config.Show_Expansion_Markers then
         if Node.Kind = Editor.File_Tree.Directory_Node then
            if Node.Is_Expanded then
               Marker := '-';
            else
               Marker := '+';
            end if;
         else
            Marker := ' ';
         end if;
      end if;

      declare
         Prefix : constant String :=
           (if Config.Show_Expansion_Markers then
              (1 .. Indent_Cols => ' ') & Marker & ' '
            else
              (1 .. Indent_Cols => ' '));
      begin
         if Width <= Prefix_Len then
            return Prefix (Prefix'First .. Prefix'First + Width - 1);
         else
            return Prefix & Truncate_Label (Label, Width - Prefix_Len);
         end if;
      end;
   end Format_Row_Text;

end Editor.File_Tree_View;
