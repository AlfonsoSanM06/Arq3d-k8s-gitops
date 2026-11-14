{{/*
Expand the name of the chart.
*/}}
{{- define "mysql-subchart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mysql-subchart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mysql-subchart.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mysql-subchart.labels" -}}
helm.sh/chart: {{ include "mysql-subchart.chart" . }}
{{ include "mysql-subchart.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: database
app.kubernetes.io/part-of: wordpress-stack
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mysql-subchart.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql-subchart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Nombre del Secret que contiene las credenciales de MySQL.
Convención: <release>-mysql-subchart-secret
El chart principal lo referencia con el mismo helper indirecto en sus values.
*/}}
{{- define "mysql-subchart.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-mysql-subchart-secret" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Nombre del PVC de MySQL
*/}}
{{- define "mysql-subchart.pvcName" -}}
{{- printf "%s-mysql-pvc" .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
StorageClass efectivo: usa persistence.storageClassName si está definido,
si no cae en global.storageClass heredado del chart padre.
*/}}
{{- define "mysql-subchart.storageClass" -}}
{{- if .Values.persistence.storageClassName }}
{{- .Values.persistence.storageClassName }}
{{- else }}
{{- .Values.global.storageClass }}
{{- end }}
{{- end }}

{{/*
Tamaño efectivo del PVC de MySQL
*/}}
{{- define "mysql-subchart.storageSize" -}}
{{- if .Values.persistence.size }}
{{- .Values.persistence.size }}
{{- else }}
{{- .Values.global.storageSize }}
{{- end }}
{{- end }}
