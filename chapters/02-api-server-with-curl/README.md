# Chapter 2: Talk to the API server with curl

This chapter was written and tested with Kubernetes 1.34.0 and kind 0.30.0.

## What you will build

Six shell scripts. A shell script is a file of commands that the shell runs in order, top to bottom, as if you typed them one by one. Each script makes a few requests to the API server with curl, the command-line tool from chapter 0 that sends HTTP requests. With them you create, read, change, watch and delete Kubernetes objects, without kubectl.

Every HTTP response starts with a number, its status code, that says how the request went. Codes in the 200s mean it worked: 200 means OK. Codes in the 400s mean the server refused: the request was wrong, or not allowed. Along the way you meet three refusals that every program that talks to Kubernetes must handle: `409 Conflict`, `410 Gone` and `403 Forbidden`. You see what each one means, and what to do about it.

Here is the `409`. Each field in it is explained in step 4, where it comes from:

```text
== writer B replaces it with owner=b, from its stale copy
{
  "code": 409,
  "reason": "Conflict",
  "message": "Operation cannot be fulfilled on configmaps \"settings\": the object has been modified; please apply your changes to the latest version and try again"
}
```

Why start with curl? Because every program you write in later chapters talks to the API server with these same requests. Once you have sent them by hand, the Go code in chapter 3 holds no surprises.

## What the real one does

The API server speaks HTTP (HyperText Transfer Protocol), the same language web browsers use to talk to web sites. As chapter 0 said, a program that sends requests is a client. So kubectl is an HTTP client, and so is curl.

> **Everyday picture.** At a bank you never walk into the vault. You hand a form through the teller's window, the teller checks it and does the work, and you get a receipt back.
>
> **In Kubernetes,** the API server is the window and kubectl is a customer. Each form is an HTTP request. A request has a method, which says what to do: `GET` to read, `POST` to create, `PUT` to replace, `PATCH` to change part of an object, and `DELETE` to remove it. It also has a path, which says which object. It can carry a body, the data you send, such as a new object. The receipt is the response: a status code, and usually a body of its own, in JSON.

(JSON stands for JavaScript Object Notation. It was invented for the JavaScript language, but now almost every program uses it.)

For example, `kubectl get pods -n ch02` lists the pods in the Kubernetes namespace `ch02`; the `-n` flag names the namespace. To do that, kubectl sends the request `GET /api/v1/namespaces/ch02/pods?limit=500`. The `?limit=500` part asks for at most 500 pods at a time. The API server answers with JSON, and kubectl turns that JSON into the table you see. To watch kubectl do this, add `-v=8` to any kubectl command. `-v` sets how much detail kubectl prints about its own work, and at 8 it prints every request and response.

Before the API server does anything, it checks the request.

> **Everyday picture.** At an airport, the passport desk checks who you are, the gate checks that your ticket lets you board this flight, and security checks what you carry. You need all three.
>
> **In Kubernetes,** the API server runs the same three gates on every request that changes something. Authentication asks who you are. Authorization asks whether you may do this. Admission asks whether the object itself is acceptable. Chapter 9 adds an admission check of your own.

Only after all three gates does the API server store the object in etcd.

Each stored object also carries one field you will see in every step of this chapter.

> **Everyday picture.** A shared online document numbers each save. If you edit from a copy you opened an hour ago, the editor warns you that someone saved since.
>
> **In Kubernetes,** that save number is the `resourceVersion`.

The API server changes an object's `resourceVersion` on every write. Clients use it in two ways. They use it to ask for every change after a known point, which is step 3. And they send it back with a change, so the API server can refuse a change made from an out-of-date copy, which is step 4.

## Scope

You do not need to know the words in this table yet. Everything on the left is explained when the chapter reaches it. Everything on the right is for later reading.

| This chapter covers | This chapter leaves out |
| --- | --- |
| Discovery: the paths `/version`, `/api` and `/apis`, which describe the API itself | OpenAPI schemas, a fuller description of every field |
| Create, get, list, merge patch, replace and delete | Server-side apply (chapter 3), and two other patch formats: JSON patch and strategic merge patch |
| Label selectors: finding objects by their labels | Field selectors, and reading a long list one page at a time |
| Watch, `resourceVersion` and `410 Gone` | Watch bookmarks |
| `409 Conflict` when a full replace uses an old copy | |
| Tokens and the cluster's certificate authority; `401` and `403` | Client certificates, and plugins that fetch credentials |

## Set up

You need the lab from [chapter 0](../00-map-and-lab/README.md). You also need curl and jq, which chapter 0 installed.

The API server only answers requests that prove who sent them. kubectl finds your proof in a file called the kubeconfig, which kind wrote when it built the cluster. The kubeconfig holds the API server's address and your credentials: the secret that proves who you are.

For steps 1 to 5, a helper takes care of the credentials. `kubectl proxy` is a small go-between that runs on your laptop. It listens for requests on port 8001 of your laptop, adds your credentials to each one, and passes it on to the API server. So curl can send requests with no credentials at all, and you can ignore credentials until step 6.

Open a second terminal window, move into the book's folder, and start the proxy there:

```bash
cd chapters/02-api-server-with-curl
make proxy
```

`cd` moves your terminal into this chapter's folder. `make proxy` runs `kubectl proxy --port=8001`. It keeps running, so leave this window open and come back to your first window. When you finish the chapter, press Ctrl+C here to stop the proxy.

Every script first reads [`env.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/env.sh). That file sets two shell variables (named boxes that hold text, read back with a `$` in front, such as `$API`):

- `API=http://127.0.0.1:8001` is the proxy's address, written as a URL, a web address. Read it in three parts: `http://` says to use HTTP, `127.0.0.1` is a special IP address that always means "this computer", and `:8001` is the port.
- `NS=ch02` is the Kubernetes namespace the scripts work in. A Kubernetes namespace, as chapter 1 warned, is a folder for objects, so this chapter's objects stay apart from everything else.

## Build it

### Step 1: look around

The API is a tree of paths, like the folders on a disk. Each path holds one kind of object. Kubernetes calls each kind of object a resource, and names its path with the plural, lowercase name: pods live at `pods`, and each pod object inside says `"kind": "Pod"`.

The resources are sorted into groups. The oldest resources, such as pods, Services, namespaces and nodes, live under `/api/v1`, and Kubernetes calls this the core group. Every newer resource belongs to a group with a name and a version, and lives under `/apis/<group>/<version>`. Deployments, for example, are in the group `apps`, version `v1`, so they live under `/apis/apps/v1`. (In this book, words in angle brackets, like `<group>`, mean "put the real name here".)

How does a client find out which resources exist, and where?

> **Everyday picture.** The board in an office lobby lists which company sits on which floor, so a visitor finds the right door without asking around.
>
> **In Kubernetes,** a few special paths, called the discovery endpoints, are that board. (An endpoint is a path the API server answers.) They list every resource the API server knows, and the path where each one lives.

[`step1/explore.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step1/explore.sh) reads the board. It is the first script in this chapter, so read it slowly: every later script uses the same building blocks.

```bash
#!/usr/bin/env bash
# Step 1: look around. Every path here is a plain HTTP GET.
set -euo pipefail
. "$(dirname "$0")/../env.sh"

echo "== version"
curl -sS "$API/version" | jq '{gitVersion, platform}'

echo "== the core group: /api/v1 and some of its resources"
curl -sS "$API/api/v1" | jq -r '.resources[] | select(.name | contains("/") | not) | .name' | head -12

echo "== named groups under /apis"
curl -sS "$API/apis" | jq -r '.groups[].preferredVersion.groupVersion' | head -12

echo "== one resource, described"
curl -sS "$API/api/v1" | jq '.resources[] | select(.name == "pods") | {name, namespaced, kind, verbs}'
```

**How to read a script.** A shell script runs its lines from top to bottom, as if you typed them one by one.

> **Everyday picture.** On a factory line, each worker does one job and hands the piece to the next worker.
>
> **In the shell,** the pipe sign `|` is that hand-off: it sends the output of the command on its left into the command on its right.

**Code walkthrough.**

1. `#!/usr/bin/env bash` on the first line says "run this file with bash", the shell program. Every other line that starts with `#` is a comment, a note that the shell ignores.
2. `set -euo pipefail` makes the script strict. It is three settings written together. `-e` stops the script at the first command that fails, meaning it ends with an exit code other than 0. `-u` treats a misspelled variable name as an error instead of as empty text. `-o pipefail` is one setting with a name: it makes a chain of `|` steps fail if any step in it fails.
3. `. "$(dirname "$0")/../env.sh"` reads the settings file. The `.` at the start runs another file inside this script, so the variables it sets stay set here. `$0` is the path of this script, and `dirname` cuts off the file name to leave its folder. `$(...)` runs a command and drops its output into the line. `..` means "the folder above". The double quotes keep the path in one piece even if a folder name has a space in it. So this reads `env.sh` from the folder above the script, and now `$API` and `$NS` are set.
4. `echo "== version"` prints a heading, so you can tell the outputs apart.
5. `curl -sS "$API/version"` sends a `GET` request to the path `/version`. `-s` turns off curl's progress bar, and `-S` still shows errors. `GET` is curl's default, so it is not written out.
6. `| jq '{gitVersion, platform}'` hands the JSON answer to jq. A jq filter is written in single quotes. The curly brackets build a new JSON object, and here it keeps just two fields of the answer: `gitVersion`, the exact Kubernetes version, and `platform`, the operating system and chip type the API server runs on.
7. The next `curl` reads `/api/v1`. jq has its own `|`, which passes data from one step of a filter to the next, inside jq. `-r` prints plain text without quotes. `.resources[]` goes through every entry in the list called `resources`. `select(...)` keeps only the entries for which the test in brackets is true, and the test, `.name | contains("/") | not`, means "the name does not contain a `/`". Names with a `/`, such as `pods/log`, are subresources: smaller parts of another resource. `.name` prints each name that is left, and the shell's `| head -12` keeps the first 12 lines.
8. The third `curl` reads `/apis`. A group can offer more than one version at once. `.groups[].preferredVersion.groupVersion` goes through every group and prints the version the API server suggests for it, such as `apps/v1`.
9. The last `curl` finds the entry whose name `==` (equals) `pods`, and shows four of its fields: its name, whether it lives in a namespace, its kind, and its verbs. The verbs are the actions the API server allows on that resource.

Run it:

```bash
bash step1/explore.sh
```

```text
== version
{
  "gitVersion": "v1.34.0",
  "platform": "linux/arm64"
}
== the core group: /api/v1 and some of its resources
bindings
componentstatuses
configmaps
...
== one resource, described
{
  "name": "pods",
  "namespaced": true,
  "kind": "Pod",
  "verbs": ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
}
```

Lines of `...` mean "more lines here, cut from the book". In the output, the verbs for pods are `get` (read one pod), `list` (read them all), `watch` (step 3), `create`, `update` (a full replace, sent with `PUT`), `patch`, `delete`, and `deletecollection` (delete many at once). `bindings` and `componentstatuses` are two more core resources, and you can ignore them for now.

This is how kubectl knows that `kubectl get deploy` (`deploy` is kubectl's short name for Deployments) means the path `/apis/apps/v1/namespaces/<namespace>/deployments`. It reads the discovery endpoints and keeps the answer on disk for a while, so it does not have to ask before every command.

### Step 2: create, read, patch, delete

These are the four basic actions on any object: create, read, update and delete, often shortened to CRUD. The script creates a pod from this file, [`step2/pod.json`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step2/pod.json). First, how to read JSON: curly brackets `{ }` hold an object, a set of named fields, each written `"name": value`. Square brackets `[ ]` hold a list. A field's value can be text in quotes, a number, `true` or `false`, another object, or a list.

```json
{
  "apiVersion": "v1",
  "kind": "Pod",
  "metadata": {
    "name": "hello",
    "labels": { "app": "hello" }
  },
  "spec": {
    "containers": [
      {
        "name": "main",
        "image": "busybox:1.37",
        "command": ["sleep", "3600"]
      }
    ]
  }
}
```

**Code walkthrough.** This is the smallest pod you can ask for.

1. `apiVersion` and `kind` say what kind of object this is: a `Pod`, from version `v1` of the core group.
2. `metadata` holds facts about the object itself. `name` is `hello`, and `labels` tags it with `app: hello`.
3. `spec` says what you want. Here it asks for one container, called `main`. Later, Kubernetes adds a third part, `status`, which reports what is really happening.
4. `image` names the image to run, busybox at version 1.37.
5. `command` is what the container runs, written as a list of words: `sleep 3600`, which waits for an hour. It does nothing useful, but it keeps the container alive long enough to look at.

[`step2/crud.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step2/crud.sh) first creates the `ch02` namespace, then sends that file to the API server. Near the top, the script sets `here=$(dirname "$0")`, the script's own folder, so it can find `pod.json` next to it.

```bash
curl -sS -X POST "$API/api/v1/namespaces/$NS/pods" \
  -H 'Content-Type: application/json' \
  -d @"$here/pod.json" \
  | jq '{name: .metadata.name, uid: .metadata.uid, resourceVersion: .metadata.resourceVersion, phase: .status.phase}'
```

**Code walkthrough.**

1. `-X POST` sets the method. `POST` means "create".
2. The path `$API/api/v1/namespaces/$NS/pods` names where the new object goes: the pods in the `ch02` namespace.
3. `-H 'Content-Type: application/json'` adds a header: a labeled line that travels with the request. This one, `Content-Type`, says the body is JSON.
4. `-d @"$here/pod.json"` sends the body. The `@` tells curl to read the body from a file, here `pod.json` in the script's own folder.
5. The `\` at the end of a line means "this command goes on, on the next line".
6. The jq filter builds a small summary of the answer with four fields. In jq, `name: .metadata.name` means "make a field called `name`, and fill it with the value at `metadata.name`". So it shows the pod's name, its `uid`, its `resourceVersion`, and `.status.phase`, a one-word summary of where the pod is in its life.

The script then reads the pod back with a plain `GET`. Then it lists only the pods with the label `app=hello`, by adding `?labelSelector=app%3Dhello` to the path. The text after `?` in a path holds options. `labelSelector` is the option that filters by label. `%3D` is how a URL writes `=` when it is part of a value, because a plain `=` already marks where an option's value starts.

When you run the script below, look at the answer to the create. The API server answers with the object as it stored it, and it holds fields you never sent. It added a `uid` (an id that no other object will ever have), a `creationTimestamp`, a `resourceVersion`, and many default settings in `spec`. And it set the pod's phase to `Pending`, which means "accepted, but its container is not running yet".

To change an object, send a `PATCH`. A patch can come in several formats, and the `Content-Type` header names the format. Here the format is a merge patch, which sends only the fields to change. This one adds a label, `chapter: two`:

```bash
curl -sS -X PATCH "$API/api/v1/namespaces/$NS/pods/hello" \
  -H 'Content-Type: application/merge-patch+json' \
  -d '{"metadata":{"labels":{"chapter":"two"}}}'
```

**Code walkthrough.**

1. `-X PATCH` sets the method to `PATCH`, "change part of this object".
2. The path ends in `/pods/hello`, so it names one pod, not the list.
3. `Content-Type: application/merge-patch+json` names the patch format.
4. The body, `{"metadata":{"labels":{"chapter":"two"}}}`, holds only the part to change. The API server merges it into the stored object, and keeps every other field as it was.

Last, the script sends a `DELETE` to the same path. It adds `?gracePeriodSeconds=0`, which asks Kubernetes not to give the pod's program any time to shut down cleanly. Run the whole script:

```bash
bash step2/crud.sh
```

```text
== create pod hello
{
  "name": "hello",
  "uid": "ddaae4be-2111-4b64-9cb6-6d3bfa0fc390",
  "resourceVersion": "424",
  "phase": "Pending"
}
...
== add a label with a merge patch
{
  "labels": { "app": "hello", "chapter": "two" },
  "resourceVersion": "425"
}
== delete it
{
  "name": "hello",
  "deletionTimestamp": "2026-11-16T22:32:03Z"
}
```

Compare the two `resourceVersion` values. The patch moved it from 424 to 425, and every write moves it.

Now look at the delete. Even with `gracePeriodSeconds=0`, the object does not vanish at once. The API server first writes a `deletionTimestamp` on the object, the moment it was marked for deletion, and returns it. (The time is written as date, `T`, time, and `Z`, which means the time is in UTC, the world's standard time zone.) So a delete is itself a write, and other parts of Kubernetes see it, and can finish their own cleanup, before the object is gone.

### Step 3: watch

Chapter 0 said every part of Kubernetes watches the API server. This step shows what watching means.

> **Everyday picture.** You can walk to the newsstand each morning, or you can subscribe once and have each new issue delivered. A subscription starts from a given issue number.
>
> **In Kubernetes,** a list is the walk to the newsstand, a watch is the subscription, and the `resourceVersion` is the issue number it starts from.

A list is a plain `GET` that returns every object of one kind, along with the `resourceVersion` of that moment. A watch is a `GET` with `watch=true` added. The API server keeps a watch open, and sends one line of JSON, called an event, each time an object changes. Each event has a `type` (`ADDED` for a new object, `MODIFIED` for a change, `DELETED` for a removal) and an `object`, the object as it is now. The client starts the watch from the list's `resourceVersion`, so it misses nothing that happened between the list and the watch.

From [`step3/watch.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step3/watch.sh). Near the top, the script sets `events=$(mktemp)`: `mktemp` makes an empty temporary file, and `events` holds its name.

```bash
rv=$(curl -sS "$API/api/v1/namespaces/$NS/pods" | jq -r '.metadata.resourceVersion')
echo "== listed pods at resourceVersion $rv; watching from there for 15 seconds"

# -N turns off curl's buffering so each event prints as it arrives.
curl -sSN "$API/api/v1/namespaces/$NS/pods?watch=true&resourceVersion=$rv&timeoutSeconds=15" > "$events" &
```

**Code walkthrough.**

1. `rv=$(curl ... | jq -r '.metadata.resourceVersion')` lists the pods and keeps only the list's `resourceVersion`, in a variable called `rv`.
2. The second `curl` starts the watch. Its options, after the `?`, are separated by `&`: `watch=true` turns the list into a watch, `resourceVersion=$rv` says where to start, and `timeoutSeconds=15` asks the API server to close the watch after 15 seconds.
3. `-N` turns off curl's buffering. Without it, curl saves up output and writes it out in chunks. With it, each event is written the moment it arrives.
4. `> "$events"` saves the watch's output to the temporary file instead of printing it.
5. The `&` at the very end of the line is the shell's `&` from chapter 1, a different thing from the `&` inside the URL. It runs the watch in the background, so the script can go on to the next line while the watch keeps listening.

Next, the script creates the `hello` pod again, changes it with a patch that adds the label `seen: yes`, and deletes it. Then it waits for the watch to finish, and prints each saved event on one line.

```bash
bash step3/watch.sh
```

```text
== events, one JSON object per line
{"type":"ADDED","name":"hello","resourceVersion":"428","labels":{"app":"hello"}}
{"type":"MODIFIED","name":"hello","resourceVersion":"429","labels":{"app":"hello"}}
{"type":"MODIFIED","name":"hello","resourceVersion":"430","labels":{"app":"hello","seen":"yes"}}
...
{"type":"DELETED","name":"hello","resourceVersion":"436","labels":{"app":"hello","seen":"yes"}}
```

Count the events. Your script made three writes, but the watch shows more. The extra events come from the rest of the cluster. The scheduler picked a node for the pod, and the kubelet on that node reported how the pod was doing. Each of those was a write, so each one is an event. You are watching the parts from chapter 0's map at work.

The delete shows up twice. First comes a `MODIFIED` event that sets `deletionTimestamp`, and then a `DELETED` event once the object is gone.

### Step 4: two writers, one conflict

Concurrency means several programs working on the same thing at the same time. Here, two programs read an object, change it and write it back. Without a check, the second write would erase the first.

> **Everyday picture.** Two clerks copy the same paper form, each makes a change, and each hands theirs back. The office stamps every form with its revision number and rejects any copy whose stamp is out of date: "someone changed this, read the new one first". Nobody locks the form while they work.
>
> **In Kubernetes,** that is optimistic concurrency, and the stamp is the `resourceVersion`.

Here is how it works. A `PUT` replaces the whole object. The writer sends back the whole object it read, and the `resourceVersion` rides along inside the object's `metadata`. If the object has changed since then, the API server rejects the `PUT` with `409 Conflict`.

The script needs an object that nothing else in the cluster will touch, so it uses a ConfigMap: an object that just holds a few named settings, in a field called `data`. This ConfigMap is called `settings`, and it has one setting, `owner`. The script keeps its path in a variable, `url`. Writer A and writer B both read it, then both try to write.

From [`step4/conflict.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step4/conflict.sh). Earlier in the script, both writers read the ConfigMap into the variables `a` and `b`, so they hold the same `resourceVersion`. Writer A has already changed it.

```bash
echo "== writer B replaces it with owner=b, from its stale copy"
echo "$b" | jq '.data.owner = "b"' \
  | curl -sS -X PUT "$url" -H 'Content-Type: application/json' -d @- \
  | jq '{code, reason, message}'
```

**Code walkthrough.**

1. `echo "$b"` prints writer B's old copy.
2. `| jq '.data.owner = "b"'` changes one setting in that copy: in jq, `=` sets a field to a new value. jq then passes the whole changed object on.
3. `| curl -sS -X PUT "$url" ... -d @-` sends it back as a `PUT`, a full replace. `-d @-` means "read the body from the pipe", the output of the step before.
4. The copy still carries the old `resourceVersion`, so the API server refuses it. The last jq shows the refusal's three fields: `code`, the status code; `reason`, one word for the problem; and `message`, a sentence for people.

The end of the script reads the ConfigMap again, makes the same change on the fresh copy, and that `PUT` succeeds. Run it:

```bash
bash step4/conflict.sh
```

```text
== writer A replaces it with owner=a
{ "owner": "a", "resourceVersion": "435" }
== writer B replaces it with owner=b, from its stale copy
{
  "code": 409,
  "reason": "Conflict",
  "message": "Operation cannot be fulfilled on configmaps \"settings\": the object has been modified; please apply your changes to the latest version and try again"
}
== writer B reads again and retries
{ "owner": "b", "resourceVersion": "436" }
```

Writer B lost, and the fix is always the same: read the object again, make the change again on the fresh copy, and write again. Every controller in this book handles a `409` this way.

### Step 5: a watch that is too old

> **Everyday picture.** A newspaper keeps back issues for a few weeks. Ask for one from last year and the office tells you to start a fresh subscription.
>
> **In Kubernetes,** that answer is `410 Gone`.

The API server cannot remember every change forever. It keeps recent changes in memory for watches. Ask a watch to start from a point older than that, and it refuses.

From [`step5/gone.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step5/gone.sh):

```bash
echo "== watch pods from resourceVersion 1"
curl -sS "$API/api/v1/namespaces/$NS/pods?watch=true&resourceVersion=1&timeoutSeconds=5" | jq -c '{type, code: .object.code, reason: .object.reason, message: .object.message}'
```

**Code walkthrough.** This is a watch like step 3, with one change: `resourceVersion=1`, a starting point from long ago. `jq -c` prints each answer on one line. The filter shows the event's `type`, and three fields from the `object` inside it.

The rest of the script lists the pods again, takes the fresh `resourceVersion`, and starts a second watch from there. For that one it uses curl's `-w` flag, which prints facts about the request after it finishes, here the address and the HTTP status code.

```bash
bash step5/gone.sh
```

```text
== watch pods from resourceVersion 1
{"type":"ERROR","code":410,"reason":"Expired","message":"too old resource version: 1 (3)"}
== the fix: list again for a fresh resourceVersion, then watch from that
fresh resourceVersion 438
watch from http://127.0.0.1:8001/api/v1/namespaces/ch02/pods?watch=true&resourceVersion=438&timeoutSeconds=2 -> HTTP 200
```

Notice where the refusal appears. The HTTP status code is 200, which means OK, because the watch itself started. The refusal arrives inside the watch, as an event of type `ERROR`, with code `410` and the reason `Expired`. Its message says the version you asked for, 1, is too old.

When does this happen in real life? A program loses its connection for a while, then tries to pick up where it left off. By then, its last `resourceVersion` is too old. It must do a fresh list, rebuild its copy of the objects from that list, and watch again from there. Chapter 3 builds an informer, the part of a client that lists, then watches, and keeps an up-to-date copy of the objects in memory. It handles `410 Gone` exactly this way.

### Step 6: no proxy

Inside a cluster, nobody uses `kubectl proxy`. Programs talk to the API server directly, over TLS (Transport Layer Security), the same encryption that protects web sites whose address starts with `https`. With TLS, the API server first proves who it is with a certificate: a file that names a server, signed by a certificate authority, a trusted signer that vouches for it. Then the program proves who it is, by sending a credential.

For a program, that credential usually belongs to a service account.

> **Everyday picture.** A visitor to an office gets a badge at the front desk. The badge names the visitor, expires at the end of the day and opens only some doors.
>
> **In Kubernetes,** a service account is an identity for a program, not a person. A token is its badge: a short string that proves the identity and expires. A role is a list of allowed actions, the doors. A role binding links a role to an account.

[`step6/direct.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step6/direct.sh) reads the API server's address and its certificate authority from your kubeconfig. It creates a service account called `reader`, and a role binding called `reader-view`. The binding links `reader` to `view`, a built-in ClusterRole that only allows reading. (A ClusterRole is a role defined once for the whole cluster; a role binding can grant it inside one namespace.) Then it asks for a short-lived token, and sends three requests: one with no token, and two with it.

Near the top, the script sets `work=$(mktemp -d)`, a temporary folder for its files. Then it reads the address and the certificate authority:

```bash
server=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 -d > "$work/ca.crt"
echo "== API server at $server"
```

**Code walkthrough.**

1. `kubectl config view --raw --minify` prints your kubeconfig. `--minify` keeps only the cluster you are using now, and `--raw` includes the secret parts that kubectl normally hides.
2. `-o jsonpath='{.clusters[0].cluster.server}'` picks out one field. jsonpath is a small language for naming a field inside JSON, like jq's filters. `clusters[0]` means the first entry in the `clusters` list, and the field is the API server's address, which the script saves in `server`.
3. The second command picks out the certificate authority's certificate. The kubeconfig stores it in base64, a way to write any data as plain letters and digits. `base64 -d` turns it back into the certificate, and `>` saves it to the file `ca.crt` (`.crt` is the usual ending for a certificate file).

Then the requests with the token:

```bash
token=$(kubectl -n "$NS" create token reader --duration=10m)

echo "== list pods as the reader"
curl -sS --cacert "$work/ca.crt" -H "Authorization: Bearer $token" \
  "$server/api/v1/namespaces/$NS/pods" | jq '{kind, items: (.items | length)}'
```

**Code walkthrough.**

1. `kubectl -n "$NS" create token reader --duration=10m` asks the API server for a token for the `reader` service account that expires after 10 minutes, and saves it in `token`.
2. `--cacert "$work/ca.crt"` tells curl to trust the API server's certificate only if the saved certificate authority signed it. This is how curl knows it is talking to the real API server.
3. `-H "Authorization: Bearer $token"` adds the token to the request. "Bearer" means "whoever holds this token is the account it names". The header's name is a historical mix-up: it carries proof of who you are, so it feeds authentication, not authorization.
4. `jq '{kind, items: (.items | length)}'` shows the kind of the answer and counts the pods in it.

The create request is the same, with `-X POST` and `pod.json` as the body. Run the script:

```bash
bash step6/direct.sh
```

```text
== without credentials
{
  "code": 403,
  "reason": "Forbidden",
  "message": "pods is forbidden: User \"system:anonymous\" cannot list resource \"pods\" in API group \"\" in the namespace \"ch02\""
}
== list pods as the reader
{ "kind": "PodList", "items": 0 }
== try to create a pod as the reader
{
  "code": 403,
  "reason": "Forbidden",
  "message": "pods is forbidden: User \"system:serviceaccount:ch02:reader\" cannot create resource \"pods\" in API group \"\" in the namespace \"ch02\""
}
```

Two requests were refused, and both refusals came from the same gate, authorization. Think back to the airport. Authentication passed both times, and the message names who the API server decided you were.

Without a token, the API server could not tell who you were, so it treated you as `system:anonymous`, the name it gives every request with no credentials. No role lets that user list pods, so authorization said no, with `403 Forbidden`. (Some clusters turn anonymous users off. Those answer `401 Unauthorized` instead, which means "I do not know who you are".)

With the token, the API server knew you were `system:serviceaccount:ch02:reader`: the service account `reader`, in the namespace `ch02`. The list worked, and returned a `PodList`, an empty list of pods. But authorization refused the create, because the `view` role only allows reading. In the message, `API group ""` means the core group, whose name is empty.

## Run it beside the real one

Now compare your scripts with kubectl. Run kubectl with `-v=8`, so it prints every request it sends:

```bash
kubectl -n ch02 get pods -v=8 2>&1 | grep -E 'GET|Response Status'
kubectl -n ch02 get pods -w -v=8 2>&1 | grep -E 'GET https'
```

kubectl writes its `-v` log to stderr, the place for error messages, not to normal output. `2>&1` sends stderr into the pipe too, so that `grep` can see it. `grep -E 'GET|Response Status'` keeps only the lines that contain `GET` or `Response Status`; inside a `grep` pattern, `|` means "or".

The first command prints a single `GET` request and the status of its response. The second, with `-w` for watch, sends a list and then a watch that starts from the list's `resourceVersion`. That is the same pattern as your step 3. The second command keeps watching, so press Ctrl+C to stop it.

## Break it

1. Watch events arrive in bursts. In [`step3/watch.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step3/watch.sh), remove the `-N` flag from the curl watch, and change `timeoutSeconds=15` to `timeoutSeconds=60`. Run it, and while it runs, create a pod by hand in another terminal with `kubectl -n ch02 run demo --image=busybox:1.37 -- sleep 3600`. The events still arrive, but in bursts, because curl is buffering again. Delete the pod with `kubectl -n ch02 delete pod demo`.
2. In [`step4/conflict.sh`](https://github.com/aarora79/k8s-book/blob/main/chapters/02-api-server-with-curl/step4/conflict.sh), change writer B's `PUT` to a merge `PATCH` that sets `data.owner` to `b`, with no `resourceVersion` in it. Now it succeeds. A patch that carries no `resourceVersion` skips the conflict check, so the last writer wins. When is that safe, and when is it not?
3. Take away the reader's role. First ask the API server whether `reader` may list pods: `kubectl auth can-i list pods -n ch02 --as=system:serviceaccount:ch02:reader` prints `yes`. (`--as` asks "what if this account sent the request?") Then delete the role binding with `kubectl -n ch02 delete rolebinding reader-view`, and ask again. Now it prints `no`. Running step 6 again would put the binding back, because the script creates it.

## Design notes

**Why you must not do math on a resourceVersion.** On your lab cluster, the `resourceVersion` is etcd's own count of writes, so it only goes up. But Kubernetes calls it opaque: a value whose meaning you are not allowed to rely on. A client may check whether two values are equal, and may send one back, and that is all. This leaves Kubernetes free to store objects differently one day. So never add to it, and never compare which one is bigger.

**Why watches expire.** The API server does not send watch events straight from etcd. It keeps a cache, a copy in memory, of recent changes, and serves every watch from that. That way thousands of clients can watch without each one holding its own connection to etcd. But memory is limited, so the cache drops old changes. etcd also throws away its own old history from time to time, which it calls compaction. `410 Gone` is the API server saying "I no longer have the changes you missed".

**Why optimistic concurrency.** The other choice is a lock: a writer claims the object, and everyone else waits until it is done. With hundreds of controllers, that waiting adds up. Optimistic concurrency lets every writer go ahead, and makes only the loser try again. That works well here, because conflicts are rare, and every controller can easily redo its change.

## Improving and expanding

1. Easy: read a long list one page at a time. Create 50 ConfigMaps with a shell loop, `for i in $(seq 1 50); do kubectl -n ch02 create configmap cm-$i; done`. Then list them with `?limit=10` on the path, and keep sending the `metadata.continue` value from each answer as `&continue=<value>` until it comes back empty.
2. Easy: filter pods on a field, with `fieldSelector=status.phase%3DRunning`. Then try a field the API server does not support, and read the error.
3. Medium: add `allowWatchBookmarks=true` to the step 3 watch, leave it open for a few minutes, and find the `BOOKMARK` events. They carry a fresh `resourceVersion` even when nothing changes. Explain how that helps a client avoid `410 Gone`.
4. Medium: change step 2 to use a JSON patch, a second patch format (`application/json-patch+json`), and use it to remove a label.
5. Hard: a pod's `status` has its own path, ending in `/status`. Send a `PUT` there, and find out which fields the API server ignores, and why.

## Further reading

- [Kubernetes API concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/): watches, resourceVersion, patches, pagination
- [Ivan Velichko, How to call the Kubernetes API using a simple HTTP client](https://iximiuz.com/en/posts/kubernetes-api-call-simple-http-client/)
- [Controlling access to the Kubernetes API](https://kubernetes.io/docs/concepts/security/controlling-access/)
