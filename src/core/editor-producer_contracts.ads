package Editor.Producer_Contracts is

   --  Phase 159 synchronous producer contract:
   --
   --  External producers must enter through feature-owned synchronous ingestion
   --  APIs. They must not mutate feature-panel projection rows, active feature
   --  state, selection, reveal tokens, mouse-hit tokens, command registrations,
   --  or feature-owned storage internals directly. Future async or external
   --  producers must convert their output into validated feature-owned rows on
   --  the editor thread or another explicitly owned synchronization boundary.
   --
   --  Forbidden shortcuts for future integrations:
   --    * Compiler output must not append diagnostics by editing projection rows.
   --    * LSP diagnostics must not bypass Diagnostics target validation.
   --    * File watchers must not mutate Messages storage directly.
   --    * Background search must not write Search Results rows without snapshot
   --      validation.
   --
   --  Phase 159 intentionally adds no compiler execution, build-output parser,
   --  LSP integration, file watcher, background worker, asynchronous queue,
   --  project-wide analysis, persistence, or fifth feature.

   type Producer_Result_Status is
     (Producer_Accepted,
      Producer_Accepted_Untargeted,
      Producer_Rejected_Empty_Text,
      Producer_Rejected_Invalid_State);

   type Producer_Result is record
      Status       : Producer_Result_Status := Producer_Rejected_Invalid_State;
      Row_Accepted : Boolean := False;
      Target_Kept  : Boolean := False;
   end record;

   function Accepted return Producer_Result;

   function Accepted_Untargeted return Producer_Result;

   function Rejected_Empty_Text return Producer_Result;

   function Rejected_Invalid_State return Producer_Result;

   function Normalize_Producer_Text (Text : String) return String;

   function Normalize_Producer_Source (Source : String) return String;

end Editor.Producer_Contracts;
