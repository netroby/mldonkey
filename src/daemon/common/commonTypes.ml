(* Copyright 2001, 2002 b8_bavard, b8_fee_carabine, INRIA *)
(*
    This file is part of mldonkey.

    mldonkey is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    mldonkey is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with mldonkey; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)


open Md4

type field_name =
  Field_Size
| Field_Filename
| Field_Artist
| Field_Album
| Field_Title
| Field_Format
| Field_Type
| Field_unknown of string

let string_of_field field =
  match field with
    Field_Size -> "size"
  | Field_Filename -> "filename"
  | Field_Artist -> "artist"
  | Field_Album -> "album"
  | Field_Title -> "title"
  | Field_Format -> "format"
  | Field_Type -> "type"
  | Field_unknown s -> s

let field_of_string s =
  match String.lowercase s with
    "size" -> Field_Size
  | "filename" -> Field_Filename
  | "artist" -> Field_Artist
  | "album" -> Field_Album
  | "title" -> Field_Title
  | "format" -> Field_Format
  | "type" -> Field_Type
  | _ -> Field_unknown s
      
type query =
  QAnd of query * query
| QOr of query * query
| QAndNot of query * query
| QHasWord of string
| QHasField of field_name * string
| QHasMinVal of field_name * int64
| QHasMaxVal of field_name * int64
| QNone (** temporary, used when no value is available ;
	   must be simplified before transforming into strings *)

  
  
  
  
  
type tag_value =
| Uint64 of int64
| Fint64 of int64
| String of string
| Addr of Ip.t
  
type tag = {
    mutable tag_name : string;
    mutable tag_value : tag_value;
  }

type client_type =
  NormalClient  (* all clients *)
| FriendClient  (* to be remembered as a friend *)
| ContactClient (* displayed with friends, but removed after disconnect *)

type query_entry = 
  Q_AND of query_entry list
| Q_OR of query_entry list
| Q_ANDNOT of query_entry * query_entry  
| Q_MODULE of string * query_entry
  
| Q_KEYWORDS of string * string
| Q_MINSIZE of string * string
| Q_MAXSIZE of string * string
| Q_FORMAT of string * string
| Q_MEDIA of string * string
  
| Q_MP3_ARTIST of string * string
| Q_MP3_TITLE of string * string
| Q_MP3_ALBUM of string * string
| Q_MP3_BITRATE of string * string

(* only internal to GUI *)
| Q_COMBO of string * string * string list
  
| Q_HIDDEN of query_entry list
  
(*
We have to add more information on what has happened to the
connection in the NotConnected state.
*)
type host_state =
| NotConnected of BasicSocket.close_reason * int (* >= 0 Queued *)
| Connecting
| Connected_initiating
| Connected of int    (* >= 0 Queued *)
| Connected_downloading
(* | ConnectionWaiting of int  *)
  
| NewHost
| RemovedHost
| BlackListedHost

type tcp_connection =
| NoConnection        (* No current connection *)
| ConnectionWaiting   (* Waiting for a connection slot to open locally *)
| ConnectionAborted   (* Abort any waiting connection slot *)
| Connection of TcpBufferedSocket.t (* We are connected *)

  
type connection_control = {
    mutable control_last_ok : int;
    mutable control_state : int;
    mutable control_last_try : int;
    mutable control_min_reask : int;
  }


type result_info = {
    mutable result_num : int;    
    result_network : int;
    
    mutable result_names : string list;
    mutable result_md4 : Md4.t;
    mutable result_size : int64;
    mutable result_format : string;
    mutable result_type : string;
    mutable result_tags : tag list;
    mutable result_comment : string;
    mutable result_done : bool;
  }
  
type output_type = TEXT | HTML | ANSI
  
type sortvd_type = 
  BySize
| ByName
| ByRate
| ByDone
| ByPercent
| ByPriority
| ByAge
| ByETA
| ByLast
| BySources
| ByASources
| ByNet
| ByAvail
| NotSorted
  
type room_state = 
| RoomOpened
| RoomClosed
| RoomPaused
  
type file
type server
type client
type result
type user
type shared  
type room

type room_message =
  ServerMessage of string
| PublicMessage of int * string
| PrivateMessage of int * string

type search_type = 
  RemoteSearch
| LocalSearch
| SubscribeSearch

type network_info = {
    network_netname : string;
    network_netnum : int;
    network_config_filename : string;
    mutable network_enabled : bool;
    mutable network_uploaded : int64;
    mutable network_downloaded : int64;
  }

type extend_search =
  ExtendSearchLocally
| ExtendSearchRemotely
  
type network = {
    network_name : string;
    network_num : int;
    mutable network_config_file : Options.options_file list;
    mutable network_incoming_subdir: (unit -> string);
    mutable network_prefix: (unit -> string);
    mutable op_network_connected_servers : (unit -> server list);
    mutable op_network_is_enabled : (unit -> bool);
    mutable op_network_save_complex_options : (unit -> unit);
    mutable op_network_load_complex_options : (unit -> unit);
    mutable op_network_enable : (unit -> unit);
    mutable op_network_disable : (unit -> unit);
    
    mutable op_network_server_of_option : 
      ((string * Options.option_value) list -> server);
    mutable op_network_add_server : 
      (Ip.addr -> int -> server);
    mutable op_network_file_of_option : 
      bool -> ((string * Options.option_value) list -> file);
    mutable op_network_client_of_option : 
      bool -> ((string * Options.option_value) list -> client);
    mutable op_network_share : (
      string -> string -> int64 -> unit);
    mutable op_network_private_message : (string -> string -> unit);
    mutable op_network_parse_url : (string -> bool);
    mutable op_network_connect_servers : (unit -> unit);
    
    mutable op_network_search : (search -> Buffer.t -> unit);
    mutable op_network_forget_search : (search -> unit);
    mutable op_network_close_search : (search -> unit);
    mutable op_network_extend_search : (search -> extend_search -> unit);
    
    mutable op_network_clean_servers : (unit -> unit);
    mutable op_network_info : (unit -> network_info);
    
    mutable op_network_connected : (unit -> bool);
  }

and   ui_user = {
    ui_user_name : string;
    mutable ui_user_searches : search list;
    mutable ui_last_search : search option;
    mutable ui_last_results : (int * result) list;
    mutable ui_http_conn : ui_conn option;
  }
      
and ui_conn = {
    mutable conn_output : output_type; 
    mutable conn_sortvd : sortvd_type;
    mutable conn_filter : (result_info -> unit);
    mutable conn_buf : Buffer.t;
    mutable conn_user : ui_user;
    mutable conn_width : int;
    mutable conn_height : int;
  }

  

and search = {
    search_num : int;
    mutable search_max_hits : int; (* total max allowed hits *)
    mutable search_type : search_type;
    mutable search_query : query;
    mutable search_nresults : int;
    mutable search_results : (int ref * result) Intmap.t;
    mutable search_waiting : int; (* how many replies are we waiting for *)
    mutable search_string : string;
    mutable search_closed : bool; (* should we continue to ask/wait for results *)
    mutable op_search_new_result_handlers : (result -> unit) list;
    mutable op_search_end_reply_handlers : (unit -> unit) list;
    mutable search_network : int;
  }

exception CommandCloseSocket
  
  
type file_state =
  FileDownloading
| FileQueued
| FilePaused
| FileDownloaded
| FileShared

| FileCancelled
| FileNew

| FileAborted of string
  
let version = 19
  

type avi_info = {
    mutable avi_codec : string;
    mutable avi_width : int;
    mutable avi_height : int;
    mutable avi_fps : int;
    mutable avi_rate : int;
  }

  
type format =
  AVI of avi_info
| MP3 of Mp3tag.Id3v1.tag * Mp3tag.info
| FormatType of string * string
| FormatUnknown
| FormatNotComputed of int

and history_result = {
    mutable hresult_names : string list;
    hresult_md4 : Md4.t;
    mutable hresult_size : int64;
    hresult_tags : tag list;
  }

and location_kind = 
  Known_location of Ip.t * int
| Indirect_location of string * Md4.t
  
(*
We should add information about what has already been sent to the GUI to
prevent sending the same information several times (for example, 
to avoid the Client_info and Result_info message before the Client_file 
message.
*)

type numevents = {
    mutable num_map : bool Intmap.t;
    mutable num_list : int list;
  }

  
type gui_record = {
    mutable gui_num : int;
    mutable gui_search_nums : int list;
    mutable gui_searches : (int * search) list;
    mutable gui_sock : TcpBufferedSocket.t option;
    mutable gui_version : int;
    mutable gui_auth : bool;
    mutable gui_poll : bool;

(* Some kind of FIFO for one time events. These events are uniq for a given
GUI, and are always sent after all other pending events. Thus, if they use
arguments, the events defining the arguments have already been sent *)
    mutable gui_new_events : event list;
    mutable gui_old_events : event list;
  
    
(* Queues of pending events for particular objects: objects updates
are kept here before being sent, so that we can easily check if a
particular update is already pending for a given GUI to avoid
sending it twice. *)
    mutable gui_files : numevents;
    mutable gui_users : numevents;
    mutable gui_clients : numevents;
    mutable gui_servers : numevents; 
    mutable gui_rooms : numevents;
    mutable gui_results : numevents;
    mutable gui_shared_files : numevents;
    
    gui_conn : ui_conn;
  }
  
and event = 
| Room_add_user_event of room * user
| Room_remove_user_event of room * user
| Room_message_event of int * room * room_message
  
| File_info_event of file
| User_info_event of user
| Client_info_event of client
| Server_info_event of server
| Room_info_event of room
| Result_info_event of result
| Shared_info_event of shared

| Client_new_file_event of client * string * result
| File_add_source_event of file * client
| File_update_availability of file * client * string
| File_remove_source_event of file * client
| Server_new_user_event of server * user
| Search_new_result_event of gui_record * int * result

| Console_message_event of string
  
exception FormatFound of format

       
type tagged_file =  {
    f_md4: Md4.t;
    f_ip: Ip.t;
    f_port: int;
    f_tags: tag list;
  }

  
let is_connected state =
  match state with
  | Connected_initiating
  | Connected_downloading
  | Connected _ -> true
  | NotConnected _
  | Connecting
  | NewHost
  | BlackListedHost
  | RemovedHost -> false

let string_of_connection_state s = 
  match s with
  | Connected (-1) -> "Connected"
  | NotConnected (_,n) -> 
      if n = -1 then "" else
      if n = 0 then  "Queued Out" else
      if n > 0 then
        Printf.sprintf "Ranked %d Out" n
      else
        Printf.sprintf "Failed %d" (- n - 1)
        
  | Connected  0 -> "Queued In"
  | Connected  n -> Printf.sprintf "Ranked %d" n
  | Connecting -> "Connecting"
  | Connected_initiating -> "Initiating"
  | Connected_downloading -> "Downloading"
      
  | RemovedHost -> "Removed"
  | BlackListedHost -> "Black"
  | NewHost -> "New"
      
let short_string_of_connection_state s = 
  match s with
  | Connected (-1) ->    "Cn'd"
  | NotConnected (_,-1) -> ""
  | NotConnected (_,0) ->    "Qout"
  | Connected  0 ->      "Qued"
  | NotConnected (_,n) ->    "Rout" 
  | Connected  n ->      "Rank" 
  | Connecting ->        "Cing"
  | Connected_initiating -> "Init"
  | Connected_downloading -> "Down"
      
  | RemovedHost -> "Rem"
  | BlackListedHost -> "BL"
  | NewHost -> "New"

open Md4
  
type file_uid =
| Bitprint of string * Sha1.t * Tiger.t
| Sha1 of string * Sha1.t
| Md5 of string * Md5.t
| Ed2k of string * Md4.t
| TigerTree of string * Tiger.t
| Md5Ext of string * Md5Ext.t     (* for Fasttrack *)
| BTUrl of string * Sha1.t
  
and file_uid_id = 
  BITPRINT | SHA1 | ED2K | MD5 | MD5EXT
  
let string_of_uid uid = 
  match uid with
    Bitprint (s,_,_) -> s
  | Sha1 (s,_) -> s
  | Ed2k (s,_) -> s
  | Md5 (s,_) -> s
  | TigerTree (s,_) -> s
  | Md5Ext (s, _) -> s
  | BTUrl (s,_) -> s
      
(* Fill the UID with a correct string representation *)
let uid_of_uid uid = 
  match uid with
    Bitprint (_,sha1,ttr) -> 
      Bitprint (Printf.sprintf "urn:bitprint:%s.%s" (Sha1.to_string sha1)
        (Tiger.to_string ttr), sha1, ttr)
  | Sha1 (_,sha1) -> 
      Sha1 (Printf.sprintf "urn:sha1:%s"  (Sha1.to_string sha1),  sha1)
  | Ed2k (_,ed2k) -> 
      Ed2k (Printf.sprintf "urn:ed2k:%s" (Md4.to_string ed2k), ed2k)
  | Md5 (_,md5) -> 
      Md5 (Printf.sprintf "urn:md5:%s" (Md5.to_string md5), md5)
  | TigerTree (_,ttr) -> 
      TigerTree (Printf.sprintf "urn:ttr:%s"  (Tiger.to_string ttr), ttr)
  | Md5Ext (_,md5) -> 
      Md5Ext (Printf.sprintf "urn:sig2dat:%s" (Md5Ext.to_base32 md5), md5)
  | BTUrl (_, url) ->
      BTUrl (Printf.sprintf "urn:bt:%s" (Sha1.to_string url), url)
      
let uid_of_string s =
  let s = String.lowercase s in
  let (urn, rem) = String2.cut_at s ':' in
  if urn <> "urn" then  failwith (Printf.sprintf "Illformed URN [%s]" s);
  let (sign, rem) = String2.cut_at rem ':' in
  uid_of_uid (match sign with
    | "ed2k" -> Ed2k ("", Md4.of_string rem)
    | "bitprint" | "bp" -> 
        let (sha1, ttr) = String2.cut_at rem '.' in
        let sha1 = Sha1.of_string sha1 in
        let tiger = Tiger.of_string ttr in
        Bitprint ("", sha1, tiger)
    | "sha1" -> Sha1 ("", Sha1.of_string rem)
    | "tree" ->
        let (tiger, rem) = String2.cut_at rem ':' in
        if tiger <> "tiger" then 
          failwith (Printf.sprintf "Illformed URN [%s]" s);
        TigerTree ("", Tiger.of_string rem)
    | "ttr" -> TigerTree ("", Tiger.of_string rem)
    | "md5" ->  Md5 ("", Md5.of_string rem)
    | "sig2dat" -> Md5Ext ("", Md5Ext.of_base32 rem)
    | "bt" | "bittorrent" -> 
        BTUrl ("", Sha1.of_string rem)
    | _ -> 
        failwith (Printf.sprintf "Illformed URN [%s]" s))

let expand_uids uids =
  let all_uids = ref [] in
  List.iter (fun uid ->
      if not (List.mem uid !all_uids) then 
        all_uids := uid :: !all_uids;
      match uid with
        Bitprint (_, sha1, tiger) ->
          let uid = uid_of_uid (Sha1 ("", sha1)) in
          if not (List.mem uid !all_uids) then 
            all_uids := uid :: !all_uids;
          let uid = uid_of_uid (TigerTree ("", tiger)) in
          if not (List.mem uid !all_uids) then 
            all_uids := uid :: !all_uids;
      | _ -> ()
  ) uids;
  !all_uids
  
  
exception IgnoreNetwork
  
let string_of_tag tag =
  match tag with
    Uint64 i| Fint64 i -> Int64.to_string i
  | Addr x -> Ip.to_string x
  | String s -> s
      

(* This structure is kept to record the informations on shared files between
  sessions *)
      
type shared_file_info = {
    sh_name : string;
    mutable sh_md4s : Md4.t list;
    sh_mtime : float;
    sh_size : int64;
    mutable sh_uids : file_uid list;
  }