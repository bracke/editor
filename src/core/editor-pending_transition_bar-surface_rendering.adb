with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Editor.Commands;
with Editor.Dirty_Guards;
with Editor.Executor;
with Editor.Pending_Transition_Bar;
with Editor.Pending_Transitions;
with Editor.Render_Layers;
with Editor.Render_Packet.Guikit_Adapters;
with Editor.State;
with Editor.Theme;

package body Editor.Pending_Transition_Bar.Surface_Rendering is

   use Editor.Render_Packet.Guikit_Adapters;

   use type Editor.Commands.Command_Id;
   use type Editor.Pending_Transitions.Pending_Transition_Kind;

   function Count_Text (Count : Natural) return String is
   begin
      return Ada.Strings.Fixed.Trim (Natural'Image (Count), Ada.Strings.Both);
   end Count_Text;

   function Truncate_To_Columns
     (Text    : String;
      Columns : Natural) return String
   is
   begin
      if Columns = 0 then
         return "";
      elsif Text'Length <= Columns then
         return Text;
      elsif Columns = 1 then
         return "~";
      else
         return Text (Text'First .. Text'First + Columns - 2) & "~";
      end if;
   end Truncate_To_Columns;

   function Dirty_Count_Text
     (Summary : Editor.Dirty_Guards.Dirty_Buffer_Summary) return String
   is
   begin
      if Summary.Dirty_Count = 1 then
         return "1 unsaved buffer";
      else
         return Count_Text (Summary.Dirty_Count) & " unsaved buffers";
      end if;
   end Dirty_Count_Text;

   function Operation_Text
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return String
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return "transition";
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return "closing buffer";
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            return "closing all buffers";
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return "closing other buffers";
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return "reloading buffer from disk";
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return "reverting buffer";
         when Editor.Pending_Transitions.Pending_Close_Project =>
            return "closing project";
         when Editor.Pending_Transitions.Pending_Clear_Project =>
            return "clearing project context";
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return "project switch";
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return "workspace restore";
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return "clearing workspace state";
      end case;
   end Operation_Text;

   function Guidance_For_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return String
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return "Retry reload after saving, or cancel to keep editing";
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return "Discard editor changes only when you want the disk version";
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return "Save changes before switching projects";
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return "Save changes before restoring the workspace";
         when Editor.Pending_Transitions.Pending_Close_Project
            | Editor.Pending_Transitions.Pending_Clear_Project =>
            return "Save or discard project changes before continuing";
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return "Confirm clear only after reviewing the workspace state";
         when Editor.Pending_Transitions.Pending_Close_Buffer
            | Editor.Pending_Transitions.Pending_Close_All_Buffers
            | Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return "Save or discard buffer changes before closing";
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return "";
      end case;
   end Guidance_For_Target;

   function Operation_For_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target)
      return Editor.Pending_Transition_Bar.Pending_Bar_Operation
   is
   begin
      case Target.Kind is
         when Editor.Pending_Transitions.No_Pending_Transition =>
            return Editor.Pending_Transition_Bar.No_Pending_Bar_Operation;
         when Editor.Pending_Transitions.Pending_Close_Buffer =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Close_Buffer_Operation;
         when Editor.Pending_Transitions.Pending_Close_All_Buffers =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Close_All_Buffers_Operation;
         when Editor.Pending_Transitions.Pending_Close_Other_Buffers =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Close_Other_Buffers_Operation;
         when Editor.Pending_Transitions.Pending_Reload_Active_Buffer =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Reload_Buffer_Operation;
         when Editor.Pending_Transitions.Pending_Revert_Active_Buffer =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Revert_Buffer_Operation;
         when Editor.Pending_Transitions.Pending_Close_Project =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Close_Project_Operation;
         when Editor.Pending_Transitions.Pending_Clear_Project =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Clear_Project_Operation;
         when Editor.Pending_Transitions.Pending_Open_Project
            | Editor.Pending_Transitions.Pending_Switch_Project
            | Editor.Pending_Transitions.Pending_Open_Recent_Project =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Project_Switch_Operation;
         when Editor.Pending_Transitions.Pending_Restore_Workspace =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Restore_Workspace_Operation;
         when Editor.Pending_Transitions.Pending_Clear_Workspace_State =>
            return Editor.Pending_Transition_Bar.Pending_Bar_Clear_Workspace_State_Operation;
      end case;
   end Operation_For_Target;

   function Is_Destructive_Target
     (Target : Editor.Pending_Transitions.Pending_Transition_Target) return Boolean
   is
   begin
      return Target.Kind in
        Editor.Pending_Transitions.Pending_Clear_Project
          | Editor.Pending_Transitions.Pending_Revert_Active_Buffer
          | Editor.Pending_Transitions.Pending_Clear_Workspace_State;
   end Is_Destructive_Target;

   function Info_For
     (Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot;
      Action   : Editor.Pending_Transition_Bar.Pending_Bar_Action)
      return Editor.Pending_Transition_Bar.Pending_Bar_Action_Info
   is
   begin
      for I in 1 .. Editor.Pending_Transition_Bar.Action_Count (Snapshot) loop
         declare
            Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
              Editor.Pending_Transition_Bar.Action (Snapshot, I);
         begin
            if Info.Action = Action then
               return Info;
            end if;
         end;
      end loop;
      return (Action         => Editor.Pending_Transition_Bar.No_Pending_Bar_Action,
              Command        => Editor.Commands.No_Command,
              Label          => Null_Unbounded_String,
              Available      => False,
              Is_Destructive => False);
   end Info_For;

   procedure Enrich_Availability
     (Snapshot : in out Editor.Pending_Transition_Bar.Pending_Bar_Snapshot;
      State    : Editor.State.State_Type)
   is
   begin
      for I in 1 .. Editor.Pending_Transition_Bar.Action_Count (Snapshot) loop
         declare
            Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
              Editor.Pending_Transition_Bar.Action (Snapshot, I);
            Availability : constant Editor.Commands.Command_Availability :=
              Editor.Executor.Command_Availability (State, Info.Command);
         begin
            Editor.Pending_Transition_Bar.Set_Action_Availability
              (Snapshot, Info.Action,
               Editor.Commands.Is_Available (Availability));
         end;
      end loop;
   end Enrich_Availability;

   procedure Push_Text
     (Texts  : in out Guikit.Draw.Text_Command_Vectors.Vector;
      Text   : String;
      X      : Float;
      Y      : Float;
      Color  : Guikit.Draw.Render_Color)
   is
   begin
      Texts.Append
        (Guikit.Draw.Text_Command'
           (X => Natural (Float'Floor (X)),
            Y => Natural (Float'Floor (Y)),
            Width => 0,
            Height => 0,
            Text => To_Unbounded_String (Text),
            Color => Color,
            others => <>));
   end Push_Text;

   procedure Build_Frame
     (State          : Editor.State.State_Type;
      Pending        : Editor.Pending_Transitions.Pending_Transition_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive;
      Visible        : out Boolean;
      Background_Rectangles : out Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Summary_Text   : out Guikit.Draw.Text_Command_Vectors.Vector;
      Action_Text    : out Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility  : out Guikit.Draw.Accessibility_Node_Vectors.Vector)
   is
      Config : constant Editor.Pending_Transition_Bar.Pending_Bar_Config := (others => <>);
      Snapshot : Editor.Pending_Transition_Bar.Pending_Bar_Snapshot :=
        Editor.Pending_Transition_Bar.Build_Snapshot (Pending, Config);
      Status_Y : constant Integer :=
        Editor.Layout.Status_Bar_Y (Layout_Config, Viewport_Height);
      Bar_Y : constant Integer :=
        Integer'Max (Layout_Config.Origin_Y, Status_Y - Integer (Cell_H));
      Bar_Layout : constant Editor.Pending_Transition_Bar.Pending_Bar_Layout :=
        Editor.Pending_Transition_Bar.Layout
          (Snapshot => Snapshot,
           Bounds_X => Layout_Config.Origin_X,
           Bounds_Y => Bar_Y,
           Bounds_W => Integer (Viewport_Width),
           Cell_W   => Cell_W,
           Cell_H   => Cell_H);
      function Action_Color
        (Info : Editor.Pending_Transition_Bar.Pending_Bar_Action_Info)
         return Guikit.Draw.Render_Color
      is
      begin
         if not Info.Available then
            return Guikit.Draw.Muted_Text_Color;
         elsif Info.Is_Destructive then
            return Guikit.Draw.Error_Text_Color;
         else
            return Guikit.Draw.Text_Color;
         end if;
      end Action_Color;
   begin
      Background_Rectangles.Clear;
      Summary_Text.Clear;
      Action_Text.Clear;
      Accessibility.Clear;
      Visible := False;

      Enrich_Availability (Snapshot, State);
      if not Editor.Pending_Transition_Bar.Is_Visible (Snapshot)
        or else Editor.Pending_Transition_Bar.Bar_W (Bar_Layout) <= 0
      then
         return;
      end if;
      Visible := True;

      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
        (X      => Natural (Editor.Pending_Transition_Bar.Bar_X (Bar_Layout)),
            Y      => Natural (Editor.Pending_Transition_Bar.Bar_Y (Bar_Layout)),
            Width  => Natural (Editor.Pending_Transition_Bar.Bar_W (Bar_Layout)),
            Height => Natural (Editor.Pending_Transition_Bar.Bar_H (Bar_Layout)),
        Color  => Guikit.Draw.Pane_Color));
      Background_Rectangles.Append
        (Guikit.Draw.Rectangle_Command'
           (X      => Natural (Editor.Pending_Transition_Bar.Bar_X (Bar_Layout)),
            Y      => Natural (Editor.Pending_Transition_Bar.Bar_Y (Bar_Layout)),
            Width  => 3,
            Height => Natural (Editor.Pending_Transition_Bar.Bar_H (Bar_Layout)),
            Color  => Guikit.Draw.Label_Orange_Color));

      declare
         Text_X : constant Float :=
           Float (Editor.Pending_Transition_Bar.Bar_X (Bar_Layout) + Integer (Cell_W));
         First_Action_X : Integer :=
           Editor.Pending_Transition_Bar.Bar_X (Bar_Layout)
           + Editor.Pending_Transition_Bar.Bar_W (Bar_Layout)
           - Integer (Cell_W);
         Available_Text_W : Natural := 0;
         Max_Cols : Natural := 0;
      begin
         for I in 1 .. Editor.Pending_Transition_Bar.Action_Rect_Count (Bar_Layout) loop
            declare
               Rect : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Rect :=
                 Editor.Pending_Transition_Bar.Action_Rect (Bar_Layout, I);
            begin
               if Rect.X < First_Action_X then
                  First_Action_X := Rect.X;
               end if;
            end;
         end loop;

         if First_Action_X > Integer (Text_X) then
            Available_Text_W := Natural (First_Action_X - Integer (Text_X));
         end if;
         Max_Cols := (if Available_Text_W > Cell_W then Available_Text_W / Cell_W else 0);
         Push_Text
           (Summary_Text,
            Truncate_To_Columns
              (Editor.Pending_Transition_Bar.Display_Text (Snapshot), Max_Cols),
            Text_X, Float (Editor.Pending_Transition_Bar.Bar_Y (Bar_Layout)),
            Guikit.Draw.Text_Color);
      end;

      for I in 1 .. Editor.Pending_Transition_Bar.Action_Rect_Count (Bar_Layout) loop
         declare
            Rect : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Rect :=
              Editor.Pending_Transition_Bar.Action_Rect (Bar_Layout, I);
            Info : constant Editor.Pending_Transition_Bar.Pending_Bar_Action_Info :=
              Info_For (Snapshot, Rect.Action);
            Label_Cols : constant Natural :=
              (if Rect.W > Integer (2 * Cell_W) then Natural (Rect.W) / Cell_W - 2 else 0);
            Label : constant String :=
              Truncate_To_Columns (To_String (Info.Label), Label_Cols);
         begin
            Push_Text
              (Action_Text, Label,
               Float (Rect.X + Integer (Cell_W)),
               Float (Rect.Y),
               Action_Color (Info));
         end;
      end loop;
   end Build_Frame;

   procedure Build_Packet
     (Packet         : in out Editor.Render_Packet.Render_Packet;
      State          : Editor.State.State_Type;
      Pending        : Editor.Pending_Transitions.Pending_Transition_State;
      Layout_Config  : Editor.Layout.Layout_Config;
      Viewport_Width : Natural;
      Viewport_Height : Natural;
      Cell_W         : Natural;
      Cell_H         : Positive)
   is
      Visible       : Boolean;
      Background    : Guikit.Draw.Rectangle_Command_Vectors.Vector;
      Summary       : Guikit.Draw.Text_Command_Vectors.Vector;
      Action        : Guikit.Draw.Text_Command_Vectors.Vector;
      Accessibility : Guikit.Draw.Accessibility_Node_Vectors.Vector;
   begin
      Build_Frame
        (State                 => State,
         Pending               => Pending,
         Layout_Config         => Layout_Config,
         Viewport_Width        => Viewport_Width,
         Viewport_Height       => Viewport_Height,
         Cell_W                => Cell_W,
         Cell_H                => Cell_H,
         Visible               => Visible,
         Background_Rectangles => Background,
         Summary_Text          => Summary,
         Action_Text           => Action,
         Accessibility         => Accessibility);

      if Visible then
         for R of Background loop
            Push_Guikit_Rectangle
              (Packet, Editor.Render_Layers.Pending_Transition_Background_Layer, R);
         end loop;
         for T of Summary loop
            Push_Guikit_Text
              (Packet, Editor.Render_Layers.Pending_Transition_Text_Layer, T);
         end loop;
         for T of Action loop
            Push_Guikit_Text
              (Packet, Editor.Render_Layers.Pending_Transition_Action_Layer, T);
         end loop;
      end if;
   end Build_Packet;

end Editor.Pending_Transition_Bar.Surface_Rendering;
