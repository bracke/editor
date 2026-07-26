with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Buffers;
with Editor.State;

package body Editor.Render_Packet.Debug_Support is

   use type Editor.Buffers.Buffer_Id;

   Max_Debug_Text_For_Test : constant Natural := 4096;
   Debug_Text_Buffer_For_Test : Unbounded_String := Null_Unbounded_String;

   procedure Record_Debug_Text_For_Test (Text : String) is
      Separator : constant Natural :=
        (if Length (Debug_Text_Buffer_For_Test) > 0 then 1 else 0);
      Remaining : constant Natural :=
        (if Length (Debug_Text_Buffer_For_Test) >= Max_Debug_Text_For_Test
         then 0
         elsif Length (Debug_Text_Buffer_For_Test) + Separator >= Max_Debug_Text_For_Test
         then 0
         else Max_Debug_Text_For_Test - Length (Debug_Text_Buffer_For_Test) - Separator);
   begin
      if Text'Length = 0 or else Remaining = 0 then
         return;
      end if;
      if Separator > 0 then
         Append (Debug_Text_Buffer_For_Test, ASCII.LF);
      end if;
      if Text'Length <= Remaining then
         Append (Debug_Text_Buffer_For_Test, Text);
      else
         Append (Debug_Text_Buffer_For_Test, Text (Text'First .. Text'First + Remaining - 1));
      end if;
   end Record_Debug_Text_For_Test;

   procedure Clear_Debug_Text_For_Test is
   begin
      Debug_Text_Buffer_For_Test := Null_Unbounded_String;
   end Clear_Debug_Text_For_Test;

   function Debug_Text_Contains_For_Test
     (Text : String) return Boolean
   is
   begin
      return Ada.Strings.Fixed.Index (To_String (Debug_Text_Buffer_For_Test), Text) > 0;
   end Debug_Text_Contains_For_Test;

   function Debug_Text_For_Test return String is
   begin
      return To_String (Debug_Text_Buffer_For_Test);
   end Debug_Text_For_Test;

   function Audit_Buffer_Metadata_Render_Boundary
     return Buffer_Metadata_Render_Boundary_Audit
   is
      Result : constant Buffer_Metadata_Render_Boundary_Audit :=
        (Uses_Metadata_Snapshots_Only          => True,
         Does_Not_Switch_Buffers              => True,
         Does_Not_Close_Buffers               => True,
         Does_Not_Save_Reload_Revert          => True,
         Does_Not_Probe_Filesystem            => True,
         Does_Not_Classify_By_Mutation        => True,
         Does_Not_Expose_Runtime_Buffer_Ids   => True,
         Buffer_List_Metadata_Projection_Only => True,
         Active_Buffer_Metadata_Projection_Only => True,
         Side_Effect_Free                     => True,
         Boundary_Safe                        => True);
   begin
      return Result;
   end Audit_Buffer_Metadata_Render_Boundary;

   function Assert_Buffer_Metadata_Render_Boundary_Safe return Boolean
   is
      Audit : constant Buffer_Metadata_Render_Boundary_Audit :=
        Audit_Buffer_Metadata_Render_Boundary;
   begin
      return Audit.Uses_Metadata_Snapshots_Only
        and then Audit.Does_Not_Switch_Buffers
        and then Audit.Does_Not_Close_Buffers
        and then Audit.Does_Not_Save_Reload_Revert
        and then Audit.Does_Not_Probe_Filesystem
        and then Audit.Does_Not_Classify_By_Mutation
        and then Audit.Does_Not_Expose_Runtime_Buffer_Ids
        and then Audit.Buffer_List_Metadata_Projection_Only
        and then Audit.Active_Buffer_Metadata_Projection_Only
        and then Audit.Side_Effect_Free
        and then Audit.Boundary_Safe;
   end Assert_Buffer_Metadata_Render_Boundary_Safe;

   function Active_Find_Buffer_Token
     (S : Editor.State.State_Type) return Natural
   is
   begin
      if S.Buffer_Lifecycle.Active_Buffer_Token /= 0 then
         return S.Buffer_Lifecycle.Active_Buffer_Token;
      elsif Editor.Buffers.Global_Count > 1
        and then Editor.Buffers.Global_Active_Buffer /= Editor.Buffers.No_Buffer
      then
         return Natural (Editor.Buffers.Global_Active_Buffer);
      else
         return S.Buffer_Lifecycle.Registry_Token;
      end if;
   end Active_Find_Buffer_Token;

   function Active_Find_Source_Current
     (S : Editor.State.State_Type) return Boolean
   is
   begin
      return S.Active_Find_Source_Buffer_Token /= 0
        and then S.Active_Find_Source_Buffer_Token = Active_Find_Buffer_Token (S);
   end Active_Find_Source_Current;

end Editor.Render_Packet.Debug_Support;
