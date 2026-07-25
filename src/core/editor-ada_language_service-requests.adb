with Editor.Commands.Descriptors; use Editor.Commands.Descriptors;
with Ada.Characters.Handling;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Diagnostic_Action_Router;
with Editor.Ada_Diagnostic_Navigation;
with Editor.Ada_Diagnostic_Panel_Projection;
with Editor.Ada_Diagnostic_Provenance;
with Editor.Ada_Diagnostic_Quick_Fix_Skeleton;
with Editor.Ada_Diagnostic_Status_Line;
with Editor.Ada_Semantic_Diagnostic_Index;
with Editor.External_Producers.Diagnostic_Line_Parsing;
with Editor.External_Producers.Diagnostic_Text_Lines;
with Editor.External_Producers.Diagnostics_Types;
with Editor.Syntax;

package body Editor.Ada_Language_Service.Requests is

   function Semantic_Request_Query_Key
     (Kind            : Semantic_Request_Kind;
      Name            : String;
      Profile_Summary : String := "";
      Detail          : String := "") return String
   is
      Separator : constant Character := Character'Val (31);
   begin
      case Kind is
         when Semantic_Request_Goto_Declaration =>
            if Detail'Length > 0 then
               return Name & Separator & Detail;
            end if;
         when Semantic_Request_Goto_Body | Semantic_Request_Goto_Spec =>
            if Profile_Summary'Length > 0 or else Detail'Length > 0 then
               return Name & Separator & Profile_Summary &
                 Separator & Detail;
            end if;
         when Semantic_Request_Completion | Semantic_Request_Rename =>
            if Detail'Length > 0 then
               return Name & Separator & Detail;
            end if;
         when others =>
            null;
      end case;

      return Name;
   end Semantic_Request_Query_Key;

   function Semantic_Current_Request_Query_Key
     (Kind                 : Semantic_Request_Kind;
      Query                : String;
      Path                 : String;
      Buffer_Token         : Natural;
      Buffer_Revision      : Natural;
      Lifecycle_Generation : Natural;
      Analysis_Fingerprint : Natural;
      Detail               : String := "") return String
   is
      Separator : constant Character := Character'Val (30);
   begin
      return Semantic_Request_Kind'Image (Kind) &
        Separator & Query &
        Separator & Path &
        Separator & Natural'Image (Buffer_Token) &
        Separator & Natural'Image (Buffer_Revision) &
        Separator & Natural'Image (Lifecycle_Generation) &
        Separator & Natural'Image (Analysis_Fingerprint) &
        Separator & Detail;
   end Semantic_Current_Request_Query_Key;

   function Begin_Semantic_Request
     (Service : in out Service_State;
      Kind    : Semantic_Request_Kind;
      Query   : String := "") return Semantic_Request_Id
   is
   begin
      Service.Previous_Request := Service.Active_Request;
      if Service.Previous_Request.Status = Semantic_Request_Pending then
         Service.Previous_Request.Status := Semantic_Request_Superseded;
         Service.Previous_Request.Result_Status := Service_Stale;
      end if;

      if Service.Next_Request_Id = Semantic_Request_Id'Last then
         Service.Next_Request_Id := 1;
      else
         Service.Next_Request_Id := Service.Next_Request_Id + 1;
      end if;

      Service.Active_Request :=
        (Id                => Service.Next_Request_Id,
         Kind              => Kind,
         Status            => Semantic_Request_Pending,
         Query             => To_Unbounded_String (Query),
         Index_Fingerprint => Editor.Ada_Project_Index.Fingerprint
           (Service.Index),
         Result_Status     => Service_Unavailable);
      return Service.Active_Request.Id;
   end Begin_Semantic_Request;

   procedure Cancel_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id) is
   begin
      if Id /= No_Semantic_Request
        and then Service.Active_Request.Id = Id
        and then Service.Active_Request.Status = Semantic_Request_Pending
      then
         Service.Active_Request.Status := Semantic_Request_Cancelled;
         Service.Active_Request.Result_Status := Service_Unavailable;
      end if;
   end Cancel_Semantic_Request;

   function Active_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status is
   begin
      return Service.Active_Request;
   end Active_Semantic_Request;

   function Previous_Semantic_Request
     (Service : Service_State) return Semantic_Request_Status is
   begin
      return Service.Previous_Request;
   end Previous_Semantic_Request;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Boolean is
   begin
      return Id /= No_Semantic_Request
        and then Service.Active_Request.Id = Id
        and then Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint =
          Editor.Ada_Project_Index.Fingerprint (Service.Index);
   end Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind) return Boolean is
   begin
      return Semantic_Request_Is_Current (Service, Id)
        and then Service.Active_Request.Kind = Kind;
   end Semantic_Request_Is_Current;

   function Semantic_Request_Is_Current
     (Service : Service_State;
      Id      : Semantic_Request_Id;
      Kind    : Semantic_Request_Kind;
      Query   : String) return Boolean
   is
      Active_Query : constant String := To_String (Service.Active_Request.Query);
   begin
      return Semantic_Request_Is_Current (Service, Id, Kind)
        and then Active_Query = Query;
   end Semantic_Request_Is_Current;

   function Request_Rejected_Status
     (Service : Service_State;
      Id      : Semantic_Request_Id) return Service_Status
   is
   begin
      if Id = No_Semantic_Request
        or else Service.Active_Request.Id /= Id
        or else Service.Active_Request.Status = Semantic_Request_No_Request
      then
         return Service_Unavailable;
      elsif Service.Active_Request.Status = Semantic_Request_Cancelled then
         return Service_Unavailable;
      else
         return Service_Stale;
      end if;
   end Request_Rejected_Status;

   procedure Finish_Semantic_Request
     (Service : in out Service_State;
      Id      : Semantic_Request_Id;
      Status  : Service_Status)
   is
   begin
      if Id = No_Semantic_Request
        or else Service.Active_Request.Id /= Id
      then
         return;
      elsif Service.Active_Request.Status = Semantic_Request_Pending
        and then Service.Active_Request.Index_Fingerprint =
          Editor.Ada_Project_Index.Fingerprint (Service.Index)
      then
         Service.Active_Request.Status := Semantic_Request_Completed;
         Service.Active_Request.Result_Status := Status;
      elsif Service.Active_Request.Status = Semantic_Request_Pending then
         Service.Active_Request.Status := Semantic_Request_Stale;
         Service.Active_Request.Result_Status := Service_Stale;
      end if;
   end Finish_Semantic_Request;

end Editor.Ada_Language_Service.Requests;
