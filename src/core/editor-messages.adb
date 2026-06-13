with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers; use type Ada.Containers.Count_Type;

package body Editor.Messages is

   Horizontal_Padding_Cells : constant Natural := 2;
   Vertical_Padding_Rows   : constant Natural := 0;
   Default_Config : constant Message_Config :=
     (Default_Lifetime_Ms   => 180,
      Error_Lifetime_Ms     => 300,
      Max_Visible_Messages  => 3,
      Max_Text_Columns      => 80,
      Replace_Same_Category => True);

   function Lifetime_For
     (Severity : Message_Severity;
      Config   : Message_Config) return Natural
   is
   begin
      case Severity is
         when Info_Message | Success_Message =>
            return Config.Default_Lifetime_Ms;
         when Warning_Message | Error_Message =>
            return Config.Error_Lifetime_Ms;
      end case;
   end Lifetime_For;

   function Expiry_Time
     (Now_Ms   : Natural;
      Lifetime : Natural) return Natural
   is
   begin
      if Natural'Last - Now_Ms < Lifetime then
         return Natural'Last;
      else
         return Now_Ms + Lifetime;
      end if;
   end Expiry_Time;

   function Is_Visible
     (Message : Message_Record;
      Now_Ms  : Natural) return Boolean
   is
   begin
      return Message.Id /= No_Message and then Now_Ms < Message.Expires_At_Ms;
   end Is_Visible;

   procedure Prune_Expired
     (State  : in out Message_State;
      Now_Ms : Natural)
   is
      I : Message_Vectors.Extended_Index := State.Queue.First_Index;
   begin
      while I <= State.Queue.Last_Index loop
         if not Is_Visible (State.Queue.Element (I), Now_Ms) then
            State.Queue.Delete (I);
         else
            I := I + 1;
         end if;
      end loop;
   end Prune_Expired;

   function Normalize_Text
     (Text        : String;
      Max_Columns : Natural) return String
   is
      Clean : String (Text'Range) := Text;
   begin
      for I in Clean'Range loop
         if Clean (I) = ASCII.CR or else Clean (I) = ASCII.LF or else Clean (I) = ASCII.HT then
            Clean (I) := ' ';
         end if;
      end loop;

      if Max_Columns = 0 then
         return "";
      elsif Clean'Length <= Max_Columns then
         return Clean;
      elsif Max_Columns <= 3 then
         return (1 .. Max_Columns => '.');
      else
         return Clean (Clean'First .. Clean'First + Max_Columns - 4) & "...";
      end if;
   end Normalize_Text;

   procedure Enforce_Capacity
     (State  : in out Message_State;
      Now_Ms : Natural;
      Config : Message_Config)
   is
   begin
      if Config.Max_Visible_Messages = 0 then
         State.Queue.Clear;
         return;
      end if;

      Prune_Expired (State, Now_Ms);
      while Natural (State.Queue.Length) > Config.Max_Visible_Messages loop
         exit when State.Queue.Length = 0;
         State.Queue.Delete (State.Queue.First_Index);
      end loop;
   end Enforce_Capacity;

   procedure Clear
     (State : in out Message_State)
   is
   begin
      State.Queue.Clear;
   end Clear;

   function Has_Messages
     (State : Message_State) return Boolean
   is
      Config : constant Message_Config := Default_Config;
   begin
      return Visible_Count (State, State.Current_Time_Ms, Config) > 0;
   end Has_Messages;

   function Is_Empty
     (State : Message_State) return Boolean
   is
   begin
      return not Has_Messages (State);
   end Is_Empty;

   procedure Push
     (State    : in out Message_State;
      Severity : Message_Severity;
      Text     : String;
      Now_Ms   : Natural;
      Config   : Message_Config)
   is
      Normalized : constant String := Normalize_Text (Text, Config.Max_Text_Columns);
      Lifetime   : constant Natural := Lifetime_For (Severity, Config);
      Expires    : constant Natural := Expiry_Time (Now_Ms, Lifetime);
      Message    : Message_Record;
   begin
      State.Current_Time_Ms := Now_Ms;
      Prune_Expired (State, Now_Ms);

      if Config.Replace_Same_Category then
         for I in State.Queue.First_Index .. State.Queue.Last_Index loop
            declare
               Existing : Message_Record := State.Queue.Element (I);
            begin
               if Is_Visible (Existing, Now_Ms)
                 and then Existing.Severity = Severity
                 and then To_String (Existing.Text) = Normalized
               then
                  Existing.Created_At_Ms := Now_Ms;
                  Existing.Expires_At_Ms := Expires;
                  State.Queue.Replace_Element (I, Existing);
                  Enforce_Capacity (State, Now_Ms, Config);
                  return;
               end if;
            end;
         end loop;
      end if;

      Message.Id := State.Next_Id;
      Message.Severity := Severity;
      Message.Text := To_Unbounded_String (Normalized);
      Message.Created_At_Ms := Now_Ms;
      Message.Expires_At_Ms := Expires;
      State.Queue.Append (Message);
      if State.Next_Id < Message_Id'Last then
         State.Next_Id := State.Next_Id + 1;
      end if;
      Enforce_Capacity (State, Now_Ms, Config);
   end Push;

   procedure Push_Info
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config)
   is
   begin
      Push (State, Info_Message, Text, Now_Ms, Config);
   end Push_Info;

   procedure Push_Success
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config)
   is
   begin
      Push (State, Success_Message, Text, Now_Ms, Config);
   end Push_Success;

   procedure Push_Warning
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config)
   is
   begin
      Push (State, Warning_Message, Text, Now_Ms, Config);
   end Push_Warning;

   procedure Push_Error
     (State  : in out Message_State;
      Text   : String;
      Now_Ms : Natural;
      Config : Message_Config)
   is
   begin
      Push (State, Error_Message, Text, Now_Ms, Config);
   end Push_Error;

   procedure Push
     (State    : in out Message_State;
      Severity : Message_Severity;
      Text     : String;
      Ticks    : Natural := 180;
      Sticky   : Boolean := False)
   is
      Config : Message_Config := Default_Config;
   begin
      if Sticky then
         Config.Error_Lifetime_Ms := Natural'Last / 2;
      else
         Config.Default_Lifetime_Ms := Ticks;
         Config.Error_Lifetime_Ms := Ticks;
      end if;
      Push (State, Severity, Text, State.Current_Time_Ms, Config);
   end Push;

   procedure Push_Info
     (State : in out Message_State;
      Text  : String)
   is
   begin
      Push (State, Info_Message, Text);
   end Push_Info;

   procedure Push_Success
     (State : in out Message_State;
      Text  : String)
   is
   begin
      Push (State, Success_Message, Text);
   end Push_Success;

   procedure Push_Warning
     (State : in out Message_State;
      Text  : String)
   is
   begin
      Push (State, Warning_Message, Text);
   end Push_Warning;

   procedure Push_Error
     (State : in out Message_State;
      Text  : String)
   is
   begin
      Push (State, Error_Message, Text, State.Current_Time_Ms, Default_Config);
   end Push_Error;

   procedure Tick
     (State  : in out Message_State;
      Now_Ms : Natural)
   is
   begin
      Prune_Expired (State, Now_Ms);
      State.Current_Time_Ms := Now_Ms;
   end Tick;

   procedure Tick
     (State : in out Message_State)
   is
   begin
      if State.Current_Time_Ms < Natural'Last then
         State.Current_Time_Ms := State.Current_Time_Ms + 1;
      end if;
      Prune_Expired (State, State.Current_Time_Ms);
   end Tick;

   procedure Dismiss_Latest
     (State : in out Message_State)
   is
   begin
      if State.Queue.Length > 0 then
         State.Queue.Delete (State.Queue.Last_Index);
      end if;
   end Dismiss_Latest;

   procedure Dismiss_All
     (State : in out Message_State)
   is
   begin
      Clear (State);
   end Dismiss_All;

   function Visible_Count
     (State  : Message_State;
      Now_Ms : Natural;
      Config : Message_Config) return Natural
   is
      Result : Natural := 0;
   begin
      if Config.Max_Visible_Messages = 0 or else State.Queue.Length = 0 then
         return 0;
      end if;

      for I in reverse State.Queue.First_Index .. State.Queue.Last_Index loop
         if Is_Visible (State.Queue.Element (I), Now_Ms) then
            Result := Result + 1;
            exit when Result = Config.Max_Visible_Messages;
         end if;
      end loop;
      return Result;
   end Visible_Count;

   function Visible_Message
     (State  : Message_State;
      Index  : Positive;
      Now_Ms : Natural;
      Config : Message_Config) return Message_Record
   is
      Seen : Natural := 0;
   begin
      if Index > Config.Max_Visible_Messages or else State.Queue.Length = 0 then
         return (Id => No_Message,
                 Severity => Info_Message,
                 Text => Null_Unbounded_String,
                 Created_At_Ms => 0,
                 Expires_At_Ms => 0);
      end if;

      for I in reverse State.Queue.First_Index .. State.Queue.Last_Index loop
         declare
            M : constant Message_Record := State.Queue.Element (I);
         begin
            if Is_Visible (M, Now_Ms) then
               Seen := Seen + 1;
               if Seen = Index then
                  return M;
               end if;
            end if;
         end;
      end loop;

      return (Id => No_Message,
              Severity => Info_Message,
              Text => Null_Unbounded_String,
              Created_At_Ms => 0,
              Expires_At_Ms => 0);
   end Visible_Message;

   function Id
     (Message : Message_Record) return Message_Id
   is
   begin
      return Message.Id;
   end Id;

   function Text
     (Message : Message_Record) return String
   is
   begin
      return To_String (Message.Text);
   end Text;

   function Severity
     (Message : Message_Record) return Message_Severity
   is
   begin
      return Message.Severity;
   end Severity;

   function Active_Message
     (State : Message_State;
      Found : out Boolean) return Editor_Message
   is
      M : constant Message_Record :=
        Visible_Message (State, 1, State.Current_Time_Ms, Default_Config);
   begin
      Found := M.Id /= No_Message;
      return M;
   end Active_Message;

   function Count
     (State : Message_State) return Natural
   is
   begin
      return Natural (State.Queue.Length);
   end Count;

   function Display_Text
     (Message : Editor_Message;
      Columns : Natural) return String
   is
   begin
      return Normalize_Text (To_String (Message.Text), Columns);
   end Display_Text;

   function Overlay_Rect
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State;
      Index           : Positive;
      Now_Ms          : Natural;
      Config          : Message_Config) return Message_Rect
   is
      Cell_W : constant Natural := Layout.Cell_W;
      Cell_H : constant Natural := Layout.Cell_H;
      Pad    : constant Natural := Cell_W;
      Gap    : constant Natural := Cell_H / 2;
      Status_Y : constant Integer := Layout.Status_Bar_Y;
      M : constant Message_Record :=
        Visible_Message (State, Index, Now_Ms, Config);
      Text_Len : Natural := 0;
      Columns  : Natural := 0;
      Max_Viewport_Columns : Natural := 1;
      Width    : Natural := 0;
      Height   : Natural := Cell_H * (1 + 2 * Vertical_Padding_Rows);
      X        : Natural := 0;
      Y        : Natural := 0;
      Base_Y   : Natural := 0;
   begin
      if M.Id = No_Message or else Viewport_Width = 0 or else Viewport_Height = 0 then
         return (Visible => False, X => 0, Y => 0, W => 0, H => 0);
      end if;

      Text_Len := To_String (M.Text)'Length;
      Max_Viewport_Columns := Natural'Max (1, (Viewport_Width / Cell_W) / 2);
      Columns := Natural'Min
        (Natural'Min (Config.Max_Text_Columns + 2 * Horizontal_Padding_Cells,
                      Max_Viewport_Columns),
         Natural'Max (1, Text_Len) + 2 * Horizontal_Padding_Cells);
      Width := Columns * Cell_W;
      if Width + Pad > Viewport_Width then
         Width := (if Viewport_Width > Pad then Viewport_Width - Pad else Viewport_Width);
      end if;

      if Viewport_Width > Width + Pad then
         X := Layout.Origin_X + Viewport_Width - Width - Pad;
      else
         X := Layout.Origin_X;
      end if;

      if Status_Y > Integer (Layout.Origin_Y + Height + Pad) then
         Base_Y := Natural (Status_Y) - Height - Pad;
      elsif Viewport_Height > Height + Pad then
         Base_Y := Layout.Origin_Y + Viewport_Height - Height - Pad;
      else
         Base_Y := Layout.Origin_Y;
      end if;

      if Index > 1 then
         declare
            Offset : constant Natural := (Index - 1) * (Height + Gap);
         begin
            if Base_Y > Offset then
               Y := Base_Y - Offset;
            else
               Y := Layout.Origin_Y;
            end if;
         end;
      else
         Y := Base_Y;
      end if;

      return (Visible => True, X => X, Y => Y, W => Width, H => Height);
   end Overlay_Rect;

   function Overlay_Rect
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State;
      Index           : Positive;
      Config          : Message_Config) return Message_Rect
   is
   begin
      return Overlay_Rect
        (Layout, Viewport_Width, Viewport_Height, State, Index, State.Current_Time_Ms, Config);
   end Overlay_Rect;

   function Overlay_Rect
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State) return Message_Rect
   is
   begin
      return Overlay_Rect
        (Layout, Viewport_Width, Viewport_Height, State, 1, State.Current_Time_Ms, Default_Config);
   end Overlay_Rect;

   function Is_In_Overlay
     (Layout          : Message_Layout;
      Viewport_Width  : Natural;
      Viewport_Height : Natural;
      State           : Message_State;
      X               : Integer;
      Y               : Integer) return Boolean
   is
      Count : constant Natural := Visible_Count (State, State.Current_Time_Ms, Default_Config);
   begin
      for I in 1 .. Count loop
         declare
            R : constant Message_Rect :=
              Overlay_Rect (Layout, Viewport_Width, Viewport_Height, State, I, State.Current_Time_Ms, Default_Config);
         begin
            if R.Visible
              and then X >= Integer (R.X)
              and then Y >= Integer (R.Y)
              and then X < Integer (R.X + R.W)
              and then Y < Integer (R.Y + R.H)
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Is_In_Overlay;

end Editor.Messages;
